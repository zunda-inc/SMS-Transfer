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
    `config.json.template`を`config.json`としてコピーし、`SLACK_API_TOKEN`と`SLACK_CHANNEL`を設定します。

    ```bash
    cp config.json.template config.json
    ```

4.  **サービスの構成**:
    systemdサービスファイル (`sms-transfer.service`) を設定し、自動起動を可能にします。

5.  **ハードウェアの接続**:
    Soracom Onyx LTE USBドングルにnano SIMカードを挿入し、Raspberry Piに接続します。

6.  **サービスの開始とテスト**:
    サービスを開始し、動作を確認します。

    ```bash
    sudo systemctl start sms-transfer.service
    sudo journalctl -u sms-transfer.service -f
    ```

7.  **サービスの有効化**:
    システム起動時にサービスが自動で開始されるように設定します。

    ```bash
    sudo systemctl enable sms-transfer.service
    ```

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
    Copy `config.json.template` to `config.json` and set your `SLACK_API_TOKEN` and `SLACK_CHANNEL`.

    ```bash
    cp config.json.template config.json
    ```

4.  **Configure Services**:
    Set up the systemd service file (`sms-transfer.service`) to enable automatic startup and background execution.

5.  **Connect Hardware**:
    Insert a nano SIM card into the Soracom Onyx LTE USB dongle and connect it to a USB port on the Raspberry Pi.

6.  **Start and Test the Service**:
    Once configured, start the service and check its operation.

    ```bash
    sudo systemctl start sms-transfer.service
    sudo journalctl -u sms-transfer.service -f
    ```

7.  **Enable the Service**:
    Configure the service to start automatically on system boot.

    ```bash
    sudo systemctl enable sms-transfer.service
    ```

-----

### 🤝 Special Thanks

This project was inspired by the [SMSForwardingBot](https://github.com/SystemzeusInc/SMSForwardingBot) published by [System Zeus Inc.](https://www.systemzeus.co.jp/). We extend our sincere gratitude for their excellent tool.

-----

### 📜 License

This project is licensed under the MIT License. See the [LICENSE.txt](/LICENSE.txt) file for details.