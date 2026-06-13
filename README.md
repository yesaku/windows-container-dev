# Windows コンテナ開発環境セットアップ

WSL2 + Ubuntu 上にコンテナ / Kubernetes 開発環境を構築するためのセットアップスクリプト集です。

## 構成

**Docker のみ**
```
Windows 11
└── WSL2
    └── Ubuntu
        └── Docker Engine
```

**Docker + Kubernetes**
```
Windows 11
└── WSL2
    └── Ubuntu
        ├── Docker Engine（ビルド・push）
        └── k3d
            └── k3s クラスタ（containerd）
                └── ローカルレジストリ経由で pull
```

開発作業はすべて WSL2 Ubuntu 内で完結します。Windows 側には特別なツールのインストールは不要です。

## リポジトリ構成

```
windows-container-dev/
├── ubuntu-on-wsl2/
│   ├── setup.ps1          # Windows 側のセットアップ（管理者で実行）
│   ├── setup-wsl.sh       # WSL2 Ubuntu 内のセットアップ
│   ├── reset-ubuntu.ps1   # Ubuntu を完全削除する
│   └── sample/
│       ├── docker-compose.yml  # Docker 動作確認用サンプル
│       ├── k3d-config.yaml     # k3d クラスタ定義
│       ├── nginx-pod.yaml      # k8s 動作確認用 Pod + Service
│       └── html/               # nginx のドキュメントルート
└── README.md
```

## 前提条件

- Windows 11
- 管理者権限
- インターネット接続

## セットアップ（ubuntu-on-wsl2）

### 1. スクリプトの準備

このリポジトリを Windows 上の任意のフォルダに配置します。

### 2. setup.ps1 を管理者で実行

スタートメニューで `powershell` と検索し、「管理者として実行」で開きます。

```powershell
cd <リポジトリのパス>\ubuntu-on-wsl2
Set-ExecutionPolicy Bypass -Scope Process
.\setup.ps1
```

スクリプトが順に以下を行います。

| ステップ | 内容 |
|----------|------|
| WSL2 有効化 | 初回は再起動が入り、ログオン後に自動で再開します |
| Ubuntu インストール | ユーザー名・パスワードを設定後、`exit` で PowerShell に戻ります |
| モード選択 | `1. Docker のみ` / `2. Docker + Kubernetes` を選択します |
| WSL2 内セットアップ | `setup-wsl.sh` を WSL2 内で自動実行します |

**モード 1: Docker のみ**

- Docker Engine・docker compose plugin

**モード 2: Docker + Kubernetes**

- Docker Engine に加えて以下をインストールします

| ツール | 役割 |
|--------|------|
| kubectl | Kubernetes 操作 CLI |
| helm | Kubernetes パッケージ管理 |
| k3d | ローカル Kubernetes クラスタ管理 |
| k9s | Kubernetes TUI ダッシュボード |

### 3. ファイルのエンコーディング

`.ps1` ファイルは **UTF-8 BOM あり** で保存してください。BOM なしの場合、日本語が文字化けして構文エラーになります。`.sh` ファイルは BOM なし UTF-8 のままにしてください。

## Ubuntu を作り直す

Ubuntu 環境を完全に削除したい場合は `reset-ubuntu.ps1` を使います。**Ubuntu 内のデータはすべて削除されます。**

```powershell
cd <リポジトリのパス>\ubuntu-on-wsl2
.\reset-ubuntu.ps1
```

## 動作確認用サンプル（Docker）

WSL2 に入り、`ubuntu-on-wsl2` フォルダで実行します。
※あくまで、`/mnt/c（Windowsファイルシステム）`は動作確認のため使用。このパスでのgit cloneはI/O速度が遅いため非推奨。

```bash
wsl
cd /mnt/c/<リポジトリのパス>/ubuntu-on-wsl2
docker compose up -d
```

ブラウザで http://localhost:8080 を開くと `sample/html/index.html` が表示されます。ファイルを編集するとリロードで即座に反映されます。

```bash
docker compose down
```

## 動作確認用サンプル（Kubernetes）

### 1. クラスタの作成

`sample/` ディレクトリに移動してからクラスタを作成します。`--volume` に `$(pwd)` を使うことで絶対パスを自動解決します。

```bash
wsl
cd /mnt/c/<リポジトリのパス>/ubuntu-on-wsl2/sample
k3d cluster create --config k3d-config.yaml --volume "$(pwd)/html:/mnt/html@all"
```

作成されるリソース:

| リソース | 内容 |
|----------|------|
| サーバーノード | 1台（コントロールプレーン） |
| エージェントノード | 1台（ワーカー） |
| ローカルレジストリ | `k3d-sample-registry.localhost:5111` |
| ポートマッピング | ホスト `8080` → クラスタ LoadBalancer `80` |

### 2. Pod のデプロイ

```bash
kubectl apply -f nginx-pod.yaml
kubectl get pod,svc   # Pod が Running になるまで待つ
```

### 3. 動作確認

```bash
curl http://localhost:8080
```

`sample/html/index.html` の内容が返れば成功です。

### 4. k9s でクラスタを確認

```bash
k9s
```

### 5. クリーンアップ

```bash
k3d cluster delete sample-cluster
```
