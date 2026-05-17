# AWX deployment for sub2api

## 日本語

このリポジトリは、`sub2api` を Oracle Linux ホストへ配布するための、
AWX 向け Ansible 構成です。

### AWX 配置ホスト

- `instance-20251213-ARM_fw` (`140.83.58.183`)

### 配布先ホスト

- `amd-instance-internal1` (`10.0.1.100`)
- `amd-instance-internal2` (`10.0.2.100`)
- `arm-instance` (`140.83.81.132`)
- `amd-instance-1` (`152.70.84.253`)
- `amd-instance-2` (`141.147.149.131`)

### 構成

- `deploy-awx.yml`: AWX コントローラーサーバー自体を Kubernetes 上に構築する playbook
- `deploy-sub2api.yml`: AWX Job Template で実行するメイン playbook
- `inventory/hosts.yml`: 初期 inventory の例
- `roles/docker`: Docker Engine と Compose plugin を導入
- `roles/awx_k8s`: `kubeadm` ベースの Kubernetes と AWX を導入
- `roles/sub2api`: 配置ディレクトリを準備して `sub2api` を起動
- `docs/AWX_K8S_SETUP.md`: 標準 Kubernetes 上で AWX を作る手順
- `k8s/awx/`: AWX Operator と AWX CR のサンプル

### AWX セットアップ

1. まずローカル Ansible から `deploy-awx.yml` を実行して、`instance-20251213-ARM_fw` に AWX を作成します。
2. AWX 作成後、このリポジトリを AWX の Project として登録します。
3. Oracle Linux の `opc` 用 SSH 鍵で Machine Credential を作成します。
4. AWX から各ホストへ到達できることを確認します。
5. Inventory を作成し、`inventory/hosts.yml` を取り込むか、同じホストを AWX 側で定義します。
6. Job Template を作成します。
7. Playbook に `deploy-sub2api.yml` を指定します。
8. Credential には上記 Machine Credential を指定します。
9. Privilege escalation を有効にします。

### AWXコントローラーサーバー構築

`deploy-awx.yml` は AWX コントローラーサーバー自体を Kubernetes 上に構築するための playbook です。

### AWX Web UI からの実行手順

1. AWX コントローラーサーバーにこのリポジトリを配置します。
   - 例: `/home/opc/awx-sub2api` に `git clone` または `scp` で配置します。
   - AWX から参照できる Git リポジトリを作成するのが推奨です。
2. AWX Web UI で Project を作成します。
   - SCM Type: `Git`
   - SCM URL: このリポジトリの Git URL
   - Branch/Revision: `main`
3. Machine Credential を作成します。
   - SSH private key: `opc` の秘密鍵
   - Privilege Escalation: sudo
4. Inventory を作成し、`inventory/hosts.yml` を取り込むか、AWX 上で同じホストとグループを定義します。
   - `awx_controller` グループには `instance-20251213-ARM_fw` を登録
   - `sub2api_targets` グループには対象ホストを登録
5. Job Template を 2 つ作成します。
   - `build-awx-controller`: Project = `awx-sub2api`, Playbook = `deploy-awx.yml`, Inventory = `awx_controller`, Credential = Machine, Privilege Escalation 有効
   - `deploy-sub2api`: Project = `awx-sub2api`, Playbook = `deploy-sub2api.yml`, Inventory = `sub2api_targets`, Credential = Machine, Privilege Escalation 有効
6. まず `build-awx-controller` を実行し、AWX コントローラーを構築します。その後 `deploy-sub2api` を実行します。

#### 役割の対応

- `deploy-awx.yml` / `roles/awx_k8s`: AWX コントローラーサーバー構築
- `deploy-sub2api.yml` / `roles/docker`, `roles/sub2api`: `sub2api` 配布

### 便利な変数

必要に応じて、AWX の Inventory vars、Group vars、Host vars、または Survey で設定します。

```yaml
sub2api_deploy_dir: /home/opc/sub2api-deploy
sub2api_env_overrides:
  TZ: Asia/Tokyo
```

AWX 自体を Ansible で作成するコマンド例:

```bash
ansible-playbook -i inventory/hosts.yml deploy-awx.yml
```

### 補足

- `instance-20251213-ARM_fw` は AWX の管理ホストであり、この playbook の配布先ではありません。
- `amd-instance-internal1` と `amd-instance-internal2` は `ProxyJump=opc@140.83.58.183` を使う前提です。
- playbook は公式の `docker-deploy.sh` を取得し、`docker-compose.yml` が未作成のときだけ初期生成を行います。
- `.env` は毎回 Ansible から生成するため、AWX 側の変数を正とする運用にできます。
- `kubeadm` ベースの Kubernetes で AWX を作る手順は `docs/AWX_K8S_SETUP.md` を参照してください。

### 配布

`package-release.sh` を使って、配布可能なアーカイブを作成できます。

```bash
./package-release.sh
```

このコマンドは、playbook、role、ドキュメント、サンプル inventory、および Kubernetes マニフェストを含む tarball を生成します。`.git` ヒストリは含みません。

#### 配布用 inventory の準備

- `inventory/hosts.example.yml` は配布用のサニタイズ済みサンプルです。
- 環境に合わせてコピーまたはリネームし、`inventory/hosts.yml` として保存してください。
- ローカルのホスト inventory は `inventory/hosts.yml` を `.gitignore` に登録して管理します。

#### 配布すべきファイル

- `deploy-awx.yml`: AWX コントローラー配布用 playbook
- `deploy-sub2api.yml`: AWX Job Template 実行用 playbook
- `docs/AWX_K8S_SETUP.md`: AWX/Kubernetes セットアップガイド
- `k8s/awx/`: AWX Operator サンプルマニフェスト
- `roles/`: Docker / AWX/K8s / sub2api 配布用 Ansible role

## English

This repository contains an AWX-friendly Ansible layout for deploying
`sub2api` to Oracle Linux hosts.

### AWX host

- `instance-20251213-ARM_fw` (`140.83.58.183`)

### Deployment targets

- `amd-instance-internal1` (`10.0.1.100`)
- `amd-instance-internal2` (`10.0.2.100`)
- `arm-instance` (`140.83.81.132`)
- `amd-instance-1` (`152.70.84.253`)
- `amd-instance-2` (`141.147.149.131`)

### Layout

- `deploy-awx.yml`: playbook for building the AWX controller server itself on Kubernetes
- `deploy-sub2api.yml`: main playbook for the AWX Job Template
- `inventory/hosts.yml`: example inventory
- `roles/docker`: installs Docker Engine and the Compose plugin
- `roles/awx_k8s`: installs `kubeadm`-based Kubernetes and AWX
- `roles/sub2api`: prepares the deployment directory and starts `sub2api`
- `docs/AWX_K8S_SETUP.md`: setup guide for running AWX on standard Kubernetes
- `k8s/awx/`: sample AWX Operator and AWX custom resource manifests

### AWX setup

1. First, run `deploy-awx.yml` from local Ansible to create AWX on `instance-20251213-ARM_fw`.
2. After AWX is up, register this repository as an AWX Project.
3. Create a Machine Credential using the Oracle Linux `opc` SSH key.
4. Confirm that AWX can reach each target host.
5. Create an Inventory and either import `inventory/hosts.yml` or define the same hosts directly in AWX.
6. Create a Job Template.
7. Set the playbook to `deploy-sub2api.yml`.
8. Attach the Machine Credential above.
9. Enable privilege escalation.

### Deploy from AWX controller

The `deploy-awx.yml` playbook builds the AWX controller server itself on Kubernetes from the AWX controller host.

### Run from AWX Web UI

1. Place this repository on the AWX controller host or make it accessible via Git.
2. Create an AWX Project:
   - SCM Type: `Git`
   - SCM URL: your repository URL
   - Branch/Revision: `main`
3. Create a Machine Credential using the `opc` SSH key and enable sudo.
4. Create Inventory and define the same hosts/groups as `inventory/hosts.yml`.
   - `awx_controller` group for `instance-20251213-ARM_fw`
   - `sub2api_targets` group for the target hosts
5. Create two Job Templates:
   - `build-awx-controller`: playbook `deploy-awx.yml`, inventory `awx_controller`, credential `Machine`, enable privilege escalation
   - `deploy-sub2api`: playbook `deploy-sub2api.yml`, inventory `sub2api_targets`, credential `Machine`, enable privilege escalation
6. Run `build-awx-controller` first, then `deploy-sub2api`.

#### Role mapping

- `deploy-awx.yml` / `roles/awx_k8s`: build AWX controller server
- `deploy-sub2api.yml` / `roles/docker`, `roles/sub2api`: deploy `sub2api`

### Useful variables

Set these in AWX Inventory vars, Group vars, Host vars, or Survey as needed.

```yaml
sub2api_deploy_dir: /home/opc/sub2api-deploy
sub2api_env_overrides:
  TZ: Asia/Tokyo
```

Example command for deploying AWX itself with Ansible:

```bash
ansible-playbook -i inventory/hosts.yml deploy-awx.yml
```

### Notes

- `instance-20251213-ARM_fw` is the AWX controller host and is not a deployment target for this playbook.
- `amd-instance-internal1` and `amd-instance-internal2` are configured to use `ProxyJump=opc@140.83.58.183`.
- The playbook downloads the official `docker-deploy.sh` bootstrap script and only initializes files when `docker-compose.yml` does not already exist.
- The `.env` file is rendered from Ansible variables each run, so AWX can remain the source of truth.
- For `kubeadm`-based Kubernetes setup, see `docs/AWX_K8S_SETUP.md`.

### Distribution

Use `package-release.sh` to create a portable distribution archive for handoff.

```bash
./package-release.sh
```

This produces a tarball containing the playbooks, role code, docs, sample inventory, and Kubernetes manifests without `.git` history.

### Inventory setup for distribution

- `inventory/hosts.example.yml` is a sanitized example for distribution.
- Copy or rename it to `inventory/hosts.yml` and update `ansible_host` values for your environment.
- Keep local host inventory out of source control by using `.gitignore` for `inventory/hosts.yml`.

### What to distribute

- `deploy-awx.yml`: AWX controller deployment playbook
- `deploy-sub2api.yml`: AWX Job Template playbook
- `docs/AWX_K8S_SETUP.md`: AWX/Kubernetes setup guide
- `k8s/awx/`: sample AWX Operator manifests
- `roles/`: Ansible roles for Docker, AWX/K8s, and sub2api deployment

## 中文

这个仓库提供了一套适用于 AWX 的 Ansible 结构，用于将 `sub2api`
部署到 Oracle Linux 主机。

### AWX 主机

- `instance-20251213-ARM_fw` (`140.83.58.183`)

### 部署目标主机

- `amd-instance-internal1` (`10.0.1.100`)
- `amd-instance-internal2` (`10.0.2.100`)
- `arm-instance` (`140.83.81.132`)
- `amd-instance-1` (`152.70.84.253`)
- `amd-instance-2` (`141.147.149.131`)

### 目录结构

- `deploy-awx.yml`: 用于从 AWX 控制器服务器向 Kubernetes 部署 AWX 的 playbook
- `deploy-sub2api.yml`: AWX Job Template 使用的主 playbook
- `inventory/hosts.yml`: 初始 inventory 示例
- `roles/docker`: 安装 Docker Engine 和 Compose 插件
- `roles/awx_k8s`: 安装基于 `kubeadm` 的 Kubernetes 与 AWX
- `roles/sub2api`: 准备部署目录并启动 `sub2api`
- `docs/AWX_K8S_SETUP.md`: 在标准 Kubernetes 上部署 AWX 的步骤说明
- `k8s/awx/`: AWX Operator 与 AWX 自定义资源示例

### AWX 设置步骤

1. 先从本地 Ansible 执行 `deploy-awx.yml`，在 `instance-20251213-ARM_fw` 上创建 AWX。
2. AWX 启动后，将此仓库注册为 AWX 的 Project。
3. 使用 Oracle Linux 的 `opc` SSH 密钥创建 Machine Credential。
4. 确认 AWX 可以连接到每一台目标主机。
5. 创建 Inventory，并导入 `inventory/hosts.yml`，或者在 AWX 中手动定义相同主机。
6. 创建 Job Template。
7. Playbook 选择 `deploy-sub2api.yml`。
8. 绑定上面的 Machine Credential。
9. 启用 privilege escalation。

### 从 AWX 控制器部署

`deploy-awx.yml` playbook 用于从 AWX 控制器服务器向 Kubernetes 构建 AWX 控制器服务器本身。

### 从 AWX Web UI 执行

1. 将此仓库放置到 AWX 控制器服务器，或通过 Git 使其可被访问。
2. 在 AWX Web UI 中创建 Project：
   - SCM Type: `Git`
   - SCM URL: 你的仓库 URL
   - Branch/Revision: `main`
3. 创建 Machine Credential，使用 `opc` 的 SSH 私钥，并启用 sudo。
4. 创建 Inventory，并定义与 `inventory/hosts.yml` 相同的主机与组。
   - `awx_controller` 组包含 `instance-20251213-ARM_fw`
   - `sub2api_targets` 组包含目标主机
5. 创建两个 Job Template：
   - `build-awx-controller`: playbook `deploy-awx.yml`，inventory `awx_controller`，credential `Machine`，启用 privilege escalation
   - `deploy-sub2api`: playbook `deploy-sub2api.yml`，inventory `sub2api_targets`，credential `Machine`，启用 privilege escalation
6. 先运行 `build-awx-controller`，然后运行 `deploy-sub2api`。

#### 角色对应

- `deploy-awx.yml` / `roles/awx_k8s`: 构建 AWX 控制器服务器
- `deploy-sub2api.yml` / `roles/docker`, `roles/sub2api`: 部署 `sub2api`

### 常用变量

可根据需要在 AWX 的 Inventory vars、Group vars、Host vars 或 Survey 中设置。

```yaml
sub2api_deploy_dir: /home/opc/sub2api-deploy
sub2api_env_overrides:
  TZ: Asia/Tokyo
```

使用 Ansible 部署 AWX 本体的示例命令:

```bash
ansible-playbook -i inventory/hosts.yml deploy-awx.yml
```

### 说明

- `instance-20251213-ARM_fw` 是 AWX 控制主机，不是这个 playbook 的部署目标。
- `amd-instance-internal1` 和 `amd-instance-internal2` 默认通过 `ProxyJump=opc@140.83.58.183` 连接。
- playbook 会下载官方 `docker-deploy.sh` 引导脚本，并且仅在 `docker-compose.yml` 不存在时执行初始化。
- `.env` 文件会在每次执行时由 Ansible 重新生成，因此可以将 AWX 变量作为唯一配置来源。
- 如果要在基于 `kubeadm` 的 Kubernetes 上部署 AWX，请参考 `docs/AWX_K8S_SETUP.md`。

### 分发

使用 `package-release.sh` 创建一个可移植的分发归档文件。

```bash
./package-release.sh
```

此归档将包含 playbook、role 代码、文档、示例 inventory 和 Kubernetes 清单，并且不包含 `.git` 历史记录。

#### 配置分发 inventory

- `inventory/hosts.example.yml` 是一个经过清理的分发示例。
- 将其复制或重命名为 `inventory/hosts.yml`，并根据你的环境更新 `ansible_host` 值。
- 使用 `.gitignore` 排除 `inventory/hosts.yml`，以避免将本地 inventory 提交到版本控制。

#### 需要分发的内容

- `deploy-awx.yml`: AWX 控制器部署 playbook
- `deploy-sub2api.yml`: AWX Job Template playbook
- `docs/AWX_K8S_SETUP.md`: AWX/Kubernetes 设置指南
- `k8s/awx/`: AWX Operator 示例清单
- `roles/`: Docker、AWX/K8s 和 sub2api 部署的 Ansible role
