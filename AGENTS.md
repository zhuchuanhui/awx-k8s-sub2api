# リポジトリガイドライン / Repository Guidelines / 仓库指南

## 日本語

### プロジェクト概要（Overview）

このリポジトリは、`sub2api` を Oracle Linux ホストへ配布し、AWX 自体も標準 Kubernetes 上へ Ansible で構築するための運用リポジトリです。`deploy-awx.yml`、`deploy-sub2api.yml`、`inventory/hosts.yml`、`roles/docker`、`roles/awx_k8s`、`roles/sub2api`、`k8s/awx` を中心に扱います。

### コーディング規約（Coding Style Guidelines）

- Ansible は role 分割を維持し、AWX 構築は `roles/awx_k8s`、Docker は `roles/docker`、sub2api 配布は `roles/sub2api` に閉じる。
- inventory は `awx_controller` と `sub2api_targets` を分離する。
- YAML は既存の2スペース系スタイルに合わせ、秘密値は vars に直書きしない。

### セキュリティ（Security considerations）

- AWX controller は、ユーザーが変更しない限り `arm-instance_fw`。
- `amd-instance-internal1` と `amd-instance-internal2` は `ProxyJump=opc@150.230.63.139` 前提を崩さない。
- SSH 秘密鍵、AWX admin password、sub2api `.env` の秘密値、bootstrap で出る一時パスワードはコミットしない。
- `host_key_checking = False` は利便性のための設定なので、本番化時はリスクを説明する。

### ビルド＆テスト手順（Build & Test）

- 構文確認: `ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook --syntax-check -i inventory/hosts.yml deploy-awx.yml`。
- sub2api 側も `deploy-sub2api.yml` に対して syntax check を行う。
- 実行後は AWX UI、Kubernetes pod 状態、`sub2api` の `curl -I http://127.0.0.1:8080` 相当の health を確認する。

### 知識＆ライブラリ（Knowledge & Library）

- Ansible、AWX Operator、Kubernetes/kubeadm、containerd、Calico、Docker Compose に関わる変更前は、利用可能なら Context7 MCP Server で `resolve-library-id` → `get-library-docs` を使う。
- Context7 が使えない場合は Ansible、AWX Operator、Kubernetes、Docker の公式ドキュメントを優先する。

### メンテナンス_ポリシー（Maintenance policy）

- 通常経路は `deploy-awx.yml` による Ansible 駆動。`docs/AWX_K8S_SETUP.md` は補助/参照扱い。
- `k3s` ではなく標準 Kubernetes を優先する。
- README 更新時は実際の playbook、role、inventory、manifest を確認してから編集する。
- 既存の未コミット変更はユーザー作業として扱い、勝手に戻さない。

## English

### Overview

This repository deploys `sub2api` to Oracle Linux hosts and builds AWX itself on standard Kubernetes through Ansible. Key areas are `deploy-awx.yml`, `deploy-sub2api.yml`, `inventory/hosts.yml`, `roles/docker`, `roles/awx_k8s`, `roles/sub2api`, and `k8s/awx`.

### Coding Style Guidelines

- Preserve Ansible role boundaries: AWX in `roles/awx_k8s`, Docker in `roles/docker`, and sub2api deployment in `roles/sub2api`.
- Keep inventory groups `awx_controller` and `sub2api_targets` separate.
- Match the existing YAML style and do not hard-code secrets in vars.

### Security considerations

- Unless changed by the user, the AWX controller is `arm-instance_fw`.
- Keep the `ProxyJump=opc@150.230.63.139` assumption for internal hosts.
- Do not commit SSH private keys, AWX admin passwords, sub2api `.env` secrets, or one-time bootstrap passwords.
- `host_key_checking = False` is convenient but risky for production; explain that risk when relevant.

### Build & Test

- Syntax check with `ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook --syntax-check -i inventory/hosts.yml deploy-awx.yml`.
- Run the same style of syntax check for `deploy-sub2api.yml`.
- After execution, verify AWX UI, Kubernetes pod status, and sub2api health such as `curl -I http://127.0.0.1:8080`.

### Knowledge & Library

- Before changes involving Ansible, AWX Operator, Kubernetes/kubeadm, containerd, Calico, or Docker Compose, use Context7 MCP Server when available: `resolve-library-id` then `get-library-docs`.
- If Context7 is unavailable, prefer official Ansible, AWX Operator, Kubernetes, and Docker docs.

### Maintenance policy

- The normal path is Ansible-driven via `deploy-awx.yml`; `docs/AWX_K8S_SETUP.md` is fallback/reference material.
- Prefer standard Kubernetes over `k3s`.
- Inspect real playbooks, roles, inventory, and manifests before README edits.
- Treat existing uncommitted changes as user work and do not revert them.

## 中文

### 项目概要

此仓库用于将 `sub2api` 部署到 Oracle Linux 主机，并通过 Ansible 在标准 Kubernetes 上构建 AWX 本体。核心文件包括 `deploy-awx.yml`、`deploy-sub2api.yml`、`inventory/hosts.yml`、`roles/docker`、`roles/awx_k8s`、`roles/sub2api` 和 `k8s/awx`。

### 编码规范

- 保持 Ansible role 边界: AWX 在 `roles/awx_k8s`，Docker 在 `roles/docker`，sub2api 部署在 `roles/sub2api`。
- inventory 中保持 `awx_controller` 与 `sub2api_targets` 分离。
- 遵循现有 YAML 风格，不要在 vars 中硬编码秘密值。

### 安全注意事项

- 除非用户变更，AWX 控制节点是 `arm-instance_fw`。
- 保持内部主机使用 `ProxyJump=opc@150.230.63.139` 的前提。
- 不要提交 SSH 私钥、AWX admin password、sub2api `.env` 秘密值或 bootstrap 一次性密码。
- `host_key_checking = False` 便于操作但有生产风险，相关场景需说明。

### 构建与测试

- 语法检查: `ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook --syntax-check -i inventory/hosts.yml deploy-awx.yml`。
- 对 `deploy-sub2api.yml` 也执行同类 syntax check。
- 执行后确认 AWX UI、Kubernetes pod 状态，以及类似 `curl -I http://127.0.0.1:8080` 的 sub2api health。

### 知识与库

- 修改 Ansible、AWX Operator、Kubernetes/kubeadm、containerd、Calico、Docker Compose 前，如可用，使用 Context7 MCP Server: `resolve-library-id` → `get-library-docs`。
- 如果 Context7 不可用，优先参考 Ansible、AWX Operator、Kubernetes、Docker 官方文档。

### 维护策略

- 常规路径是 `deploy-awx.yml` 的 Ansible 驱动；`docs/AWX_K8S_SETUP.md` 是备用/参考材料。
- 优先标准 Kubernetes，而不是 `k3s`。
- README 编辑前先检查真实 playbook、role、inventory 和 manifest。
- 将已有未提交修改视为用户工作，不要擅自还原。
