# AWX on Kubernetes Setup

このドキュメントは、`instance-20251213-ARM_fw` 上で通常の `Kubernetes`
を使って AWX を作成し、あとから同じ手順を何度でも再実行できるように
まとめたものです。

対象日付: 2026-04-27

## 前提

- 対象ホスト: `instance-20251213-ARM_fw`
- OS: Oracle Linux 8 / 9 系を想定
- AWX は Kubernetes 上で動かす
- Kubernetes は `kubeadm` ベースの標準構成を使う
- 管理対象ホストは以下
  - `amd-instance-internal1`
  - `amd-instance-internal2`
  - `arm-instance`
  - `amd-instance-1`
  - `amd-instance-2`

## 方針

- 単一ノードの Kubernetes を `kubeadm` で構築する
- Container runtime は `containerd` を使う
- CNI は `Calico` を例にする
- AWX は `AWX Operator` で管理する
- AWX の画面公開は最初は `NodePort` で始める
- 配布 playbook はこのリポジトリの `deploy-sub2api.yml` を使う
- `deploy-awx.yml` は AWX コントローラーサーバー自体を Kubernetes 上に構築するための playbook です

## ディレクトリ

このリポジトリには以下の Kubernetes 用サンプルを含めています。

- `k8s/awx/kustomization.yaml`
- `k8s/awx/awx.yaml`

## 1. ホスト準備

`instance-20251213-ARM_fw` に SSH で接続します。

```bash
ssh instance-20251213-ARM_fw
```

必要であれば更新を入れます。

```bash
sudo dnf update -y
```

必要パッケージを入れます。

```bash
sudo dnf install -y curl tar socat conntrack-tools iproute-tc
```

SELinux は運用方針に合わせて調整してください。検証用途でまず進めるなら、
以下で permissive にします。

```bash
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
```

swap は無効化します。

```bash
sudo swapoff -a
sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab
```

カーネルモジュールと sysctl を設定します。

```bash
cat <<'EOF' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<'EOF' | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

ファイアウォールを使う場合は、最初に少なくとも以下を開けます。

```bash
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --permanent --add-port=10259/tcp
sudo firewall-cmd --permanent --add-port=10257/tcp
sudo firewall-cmd --permanent --add-port=30080/tcp
sudo firewall-cmd --reload
```

## 2. containerd のインストール

```bash
sudo dnf install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable --now containerd
sudo systemctl status containerd --no-pager
```

## 3. Kubernetes パッケージのインストール

Kubernetes リポジトリを追加します。

```bash
cat <<'EOF' | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
```

パッケージを入れます。

```bash
sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet
```

確認します。

```bash
kubeadm version
kubectl version --client
```

## 4. Kubernetes クラスタの初期化

単一ノードクラスタとして初期化します。Pod CIDR は `Calico` に合わせて
`192.168.0.0/16` を使います。

```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

`opc` ユーザーでも `kubectl` を使えるようにします。

```bash
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown opc:opc ~/.kube/config
```

確認します。

```bash
kubectl get nodes
```

単一ノードでワーカ兼用にするため、control-plane の taint を外します。

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## 5. CNI の導入

この手順では `Calico` を使います。

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/calico.yaml
```

起動確認:

```bash
kubectl get pods -n kube-system
kubectl get nodes
```

## 6. デフォルト StorageClass の確認

AWX は PostgreSQL や projects 用に永続ストレージを使うため、
動作する `StorageClass` が必要です。

確認:

```bash
kubectl get storageclass
```

もし何も無い場合は、環境に合う CSI や local provisioner を別途入れてください。
このサンプルの `awx.yaml` は特定の StorageClass 名を固定していません。

## 7. AWX Operator 用ファイルの配置

このリポジトリを `instance-20251213-ARM_fw` に配置します。
方法は `git clone` でも `scp` でも構いません。

例:

```bash
git clone https://github.com/zhuchuanhui/awx-sub2api.git awx-sub2api
cd awx-sub2api
```

もし Git を使わずに置く場合でも、最低限以下が必要です。

- `k8s/awx/kustomization.yaml`
- `k8s/awx/awx.yaml`

## 8. AWX Operator のデプロイ

`k8s/awx/kustomization.yaml` を使って Operator と AWX CR をまとめて適用します。

```bash
cd k8s/awx
kubectl apply -k .
```

Operator の起動確認:

```bash
kubectl -n awx get pods
kubectl -n awx logs deployment/awx-operator-controller-manager -c awx-manager -f
```

AWX 本体の作成状況確認:

```bash
kubectl -n awx get awx
kubectl -n awx get pods -l app.kubernetes.io/managed-by=awx-operator
kubectl -n awx get svc
```

## 9. AWX ログイン情報の取得

管理者パスワードを取得します。

```bash
kubectl -n awx get secret awx-admin-password -o jsonpath="{.data.password}" | base64 --decode ; echo
```

このサンプルは `metadata.name: awx` を使っているため、secret 名は
`awx-admin-password` です。

## 10. AWX へアクセス

このサンプルでは `NodePort 30080` で公開します。

ブラウザ:

```text
http://140.83.58.183:30080/
```

初期ユーザー:

```text
admin
```

## 11. AWX 側の初期設定

AWX にログインしたら以下を作ります。

1. Organization
2. Machine Credential
3. Project
4. Inventory
5. Job Template

### Machine Credential

- Type: `Machine`
- Username: `opc`
- SSH Private Key: 配布対象へ接続できる秘密鍵
- Privilege Escalation Method: `sudo`

### Project

- SCM Type: `Git`
- SCM URL: `https://github.com/zhuchuanhui/awx-sub2api.git`

### Inventory

- `inventory/hosts.yml` を使うか、同じ内容を AWX 上で登録

### Job Template

- Playbook: `deploy-sub2api.yml`
- Inventory: 上で作成した Inventory
- Credential: Machine Credential
- Privilege Escalation: Enabled

## 12. 内部ホストへの到達

`amd-instance-internal1` と `amd-instance-internal2` は
`instance-20251213-ARM_fw` 経由で届く前提です。

このリポジトリの `inventory/hosts.yml` には、以下が設定されています。

```yaml
ansible_ssh_common_args: -o ProxyJump=opc@140.83.58.183
```

つまり AWX が `instance-20251213-ARM_fw` 上で動いていれば、そのまま同じ踏み台経路を使えます。

## 13. よく使う確認コマンド

Kubernetes 関連:

```bash
kubectl get nodes
kubectl get pods -A
kubectl get storageclass
```

AWX 関連:

```bash
kubectl -n awx get all
kubectl -n awx get pvc
kubectl -n awx logs deployment/awx-operator-controller-manager -c awx-manager --tail=200
kubectl -n awx describe awx awx
```

AWX サービス確認:

```bash
kubectl -n awx get svc awx-service
curl -I http://127.0.0.1:30080
```

## 14. 再作成手順

同じホストで AWX を作り直すときは、基本的に次の流れです。

1. `containerd` と `kubelet` が動いていることを確認
2. `kubectl get nodes` でクラスタが生きていることを確認
3. ストレージクラスがあることを確認
4. リポジトリを配置
5. `cd k8s/awx`
6. `kubectl apply -k .`
7. `kubectl -n awx get pods`
8. `kubectl -n awx get secret awx-admin-password -o jsonpath="{.data.password}" | base64 --decode ; echo`

## 15. 削除手順

AWX だけ消す場合:

```bash
cd k8s/awx
kubectl delete -f awx.yaml
```

Operator ごと消す場合:

```bash
cd k8s/awx
kubectl delete -k .
```

`PersistentVolumeClaim` が残ることがあるため、完全に消すなら最後に確認します。

```bash
kubectl -n awx get pvc
```

## 16. 運用メモ

- 最初は `NodePort` で十分
- 安定運用に入ったら `Ingress + TLS` を追加
- AWX のバックアップは PostgreSQL と secrets をセットで考える
- Operator や AWX のバージョンアップ前にはバックアップを取る
