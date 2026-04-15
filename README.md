## プロジェクト名：SMS Transfer

このプロジェクトは、**Soracom Onyx LTE USBドングル**を通じて受信したSMSメッセージを、**Slack**に自動で転送するPythonツールです。Raspberry Piを活用することで、IoTデバイスからの通知や重要なメッセージをリアルタイムでチームに共有できます。

-----

### 🚀 主な機能

  - **SMSの自動転送**: USBドングルが受信したSMSメッセージを検知し、設定済みのSlackチャンネルに瞬時に転送します。
  - **シンプルなセットアップ**: 依存パッケージのインストールと、簡単な設定ファイル (`config.json`) の編集だけで動作します。
  - **Raspberry Pi対応**: Raspberry Pi 4B+での動作を想定しており、省電力かつコンパクトな環境で運用可能です。

-----

### 🛠️ 必要なもの

  - **ハードウェア**

      - Raspberry Pi (4B+ 推奨)
      - [Soracom Onyx - LTE™ USB ドングル (SC-QGLC4-C1)](https://soracom.jp/store/7326/)
      - nano SIMカード

  - **ソフトウェア**

      - Network Manager
      - Modem Manager

-----

### ⚙️ セットアップ手順

1.  **依存パッケージのインストール**:
    必要なパッケージをインストールします。

    ```bash
    # 必要に応じて、OSとパッケージリストを更新
    sudo apt update
    sudo apt upgrade -y

    # Network Manager, Modem Manager, pipをインストール
    sudo apt install network-manager modemmanager python3-pip -y

    # Pythonの依存パッケージをインストール
    pip3 install -r requirements.txt
    ```

2.  **セルラーネットワークの設定**:
    Network ManagerとModem Managerを使用して、USBドングルがセルラーネットワークに接続できるよう設定します。

3.  **設定ファイルの準備**:
    `config_sample.json`を`config.json`としてコピーし、SlackトークンとチャンネルIDを設定します。

    ```bash
    cp config_sample.json config.json
    # config.json を編集して slack.token と slack.channel を設定する
    chmod 600 config.json  # 他ユーザーから保護
    ```

    | キー | 説明 |
    |------|------|
    | `slack.token` | Slack Bot Token (`xoxb-...`) |
    | `slack.channel` | 転送先チャンネル (例: `#alerts`) |
    | `general.interval` | ドングルのポーリング間隔 (秒) |

4.  **パスのカスタマイズ**:
    `sms2slack.service` および `wwan_reconnect.service` 内の `ExecStart` パスを、実際のインストール先に合わせて変更します。デフォルトは `/opt/sms-transfer/` を想定しています。

    また、`wwan_reconnect.service` が参照する環境ファイルを作成します。

    ```bash
    sudo mkdir -p /etc/sms-transfer
    echo "CONNECTION_NAME=<your-connection-name>" | sudo tee /etc/sms-transfer/env
    sudo chmod 600 /etc/sms-transfer/env
    # 接続名の確認: nmcli c show
    ```

5.  **サービスの構成**:
    systemdサービスファイルをコピーし、デーモンをリロードします。

    ```bash
    sudo cp sms2slack.service /etc/systemd/system/
    sudo cp wwan_reconnect.service /etc/systemd/system/
    sudo systemctl daemon-reload
    ```

    > **注意**: `sms2slack.service` はデフォルトで `User=pi` で動作します。異なるユーザーで実行する場合はサービスファイルを編集してください。

6.  **ハードウェアの接続**:
    Soracom Onyx LTE USBドングルにnano SIMカードを挿入し、Raspberry Piに接続します。

7.  **サービスの開始とテスト**:
    サービスを開始し、動作を確認します。

    ```bash
    sudo systemctl start sms2slack.service
    sudo journalctl -u sms2slack.service -f
    ```

8.  **サービスの有効化**:
    システム起動時にサービスが自動で開始されるように設定します。

    ```bash
    sudo systemctl enable sms2slack.service
    sudo systemctl enable wwan_reconnect.service
    ```

-----

### 🔧 トラブルシューティング

| 症状 | 確認コマンド |
|------|------------|
| SMSが届かない | `mmcli -L` でモデムが認識されているか確認 |
| Slackに転送されない | `journalctl -u sms2slack -f` でエラーを確認 |
| 接続が切れる | `nmcli c show` で接続名を確認し、`/etc/sms-transfer/env` の `CONNECTION_NAME` と一致しているか確認 |
| サービスが起動しない | `systemctl status sms2slack.service` で詳細を確認 |

-----

### 🤝 謝辞

このプロジェクトは、[株式会社システムゼウス](https://www.systemzeus.co.jp/)が公開している[SMSForwardingBot](https://github.com/SystemzeusInc/SMSForwardingBot)を参考にさせていただきました。心より感謝申し上げます。

-----

### 📜 ライセンス

本プロジェクトはMITライセンスのもとで公開されています。詳細は[LICENSE.txt](/LICENSE.txt)ファイルをご覧ください。

-----

## Project Name: SMS Transfer

This project is a Python tool that automatically relays SMS messages received via a **Soracom Onyx LTE USB dongle** to **Slack**. By using a Raspberry Pi, you can share notifications and important messages from IoT devices with your team in real time.

-----

### 🚀 Key Features

  - **Automatic SMS Forwarding**: Detects SMS messages received by the USB dongle and instantly forwards them to a configured Slack channel.
  - **Easy Setup**: The tool is operational with a simple installation of dependencies and a quick edit of the configuration file (`config.json`).
  - **Raspberry Pi Compatibility**: Designed for use with a Raspberry Pi 4B+, offering a low-power and compact solution.

-----

### 🛠️ Requirements

  - **Hardware**

      - Raspberry Pi (4B+ Recommended)
      - [Soracom Onyx - LTE™ USB Dongle (SC-QGLC4-C1)](https://soracom.jp/store/7326/)
      - nano SIM card

  - **Software**

      - Network Manager
      - Modem Manager

-----

### ⚙️ Setup Instructions

1.  **Install Dependencies**:
    Install the necessary packages.

    ```bash
    # Update the OS and package lists as needed
    sudo apt update
    sudo apt upgrade -y

    # Install Network Manager, Modem Manager, and pip
    sudo apt install network-manager modemmanager python3-pip -y

    # Install Python dependencies
    pip3 install -r requirements.txt
    ```

2.  **Configure Cellular Network**:
    Use Network Manager and Modem Manager to configure the USB dongle to connect to the cellular network.

3.  **Prepare the Configuration File**:
    Copy `config_sample.json` to `config.json` and fill in your Slack token and channel.

    ```bash
    cp config_sample.json config.json
    # Edit config.json to set slack.token and slack.channel
    chmod 600 config.json  # Protect from other users
    ```

    | Key | Description |
    |-----|-------------|
    | `slack.token` | Slack Bot Token (`xoxb-...`) |
    | `slack.channel` | Target channel (e.g. `#alerts`) |
    | `general.interval` | Dongle polling interval in seconds |

4.  **Customize Paths**:
    Update the `ExecStart` path in both `sms2slack.service` and `wwan_reconnect.service` to match your installation directory. The default assumes `/opt/sms-transfer/`.

    Also create the environment file used by `wwan_reconnect.service`:

    ```bash
    sudo mkdir -p /etc/sms-transfer
    echo "CONNECTION_NAME=<your-connection-name>" | sudo tee /etc/sms-transfer/env
    sudo chmod 600 /etc/sms-transfer/env
    # Check your connection name: nmcli c show
    ```

5.  **Configure Services**:
    Copy the service files and reload the daemon.

    ```bash
    sudo cp sms2slack.service /etc/systemd/system/
    sudo cp wwan_reconnect.service /etc/systemd/system/
    sudo systemctl daemon-reload
    ```

    > **Note**: `sms2slack.service` runs as `User=pi` by default. Edit the service file if your deployment user is different.

6.  **Connect Hardware**:
    Insert a nano SIM card into the Soracom Onyx LTE USB dongle and connect it to a USB port on the Raspberry Pi.

7.  **Start and Test the Service**:
    Once configured, start the service and check its operation.

    ```bash
    sudo systemctl start sms2slack.service
    sudo journalctl -u sms2slack.service -f
    ```

8.  **Enable the Service**:
    Configure the service to start automatically on system boot.

    ```bash
    sudo systemctl enable sms2slack.service
    sudo systemctl enable wwan_reconnect.service
    ```

-----

### 🔧 Troubleshooting

| Symptom | Command |
|---------|---------|
| No SMS detected | `mmcli -L` — check modem is recognized |
| Not forwarding to Slack | `journalctl -u sms2slack -f` — check for errors |
| Connection drops | `nmcli c show` — verify connection name matches `CONNECTION_NAME` in `/etc/sms-transfer/env` |
| Service won't start | `systemctl status sms2slack.service` — check detailed status |

-----

### 🤝 Special Thanks

This project was inspired by the [SMSForwardingBot](https://github.com/SystemzeusInc/SMSForwardingBot) published by [System Zeus Inc.](https://www.systemzeus.co.jp/). We extend our sincere gratitude for their excellent tool.

-----

### 📜 License

This project is licensed under the MIT License. See the [LICENSE.txt](/LICENSE.txt) file for details.