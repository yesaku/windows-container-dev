# Windows コンテナ開発環境セットアップ

WSL2 + Docker Engine でコンテナ開発環境を構築するためのセットアップスクリプト集です。

## 構成

```
Windows 11
└── WSL2
    └── Ubuntu
        └── Docker Engine
            └── コンテナ（開発環境）
```

開発作業はすべて WSL2 Ubuntu 内で完結します。Windows 側には特別なツールのインストールは不要です。

## リポジトリ構成

```
windows-container-dev/
├── ubuntu-on-wsl2/      # WSL2 + Docker Engine によるセットアップ
│   ├── setup.ps1        # Windows 側のセットアップ（管理者で実行）
│   ├── setup-wsl.sh     # WSL2 Ubuntu 内の Docker セットアップ
│   ├── reset-ubuntu.ps1 # Ubuntu を完全削除する
│   └── sample/
|       ├── docker-compose.yml # nginx 動作確認用サンプル
│       └── html/              # nginx のドキュメントルート
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
| Docker Engine インストール | `setup-wsl.sh` を WSL2 内で自動実行します |
| WSL2 自動起動 | ログオン時に Ubuntu が自動起動するタスクを登録します |

### 3. ファイルのエンコーディング

`.ps1` ファイルは **UTF-8 BOM あり** で保存してください。BOM なしの場合、日本語が文字化けして構文エラーになります。`.sh` ファイルは BOM なし UTF-8 のままにしてください。

## Ubuntu を作り直す

Ubuntu 環境を完全に削除したい場合は `reset-ubuntu.ps1` を使います。**Ubuntu 内のデータはすべて削除されます。**

```powershell
cd <リポジトリのパス>\ubuntu-on-wsl2
.\reset-ubuntu.ps1
```

## 動作確認用サンプル（nginx）

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
