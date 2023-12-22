#!/usr/bin/env python3
import json
import time

from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

import gi
gi.require_version('ModemManager', '1.0')
from gi.repository import Gio, ModemManager


with open('/home/shirakobato/sms2slack/config.json') as f:
    config = json.load(f)

def transfer_to_slack(text):
    client = WebClient(token=config['slack']['token'])
    try:
        response = client.chat_postMessage(channel=config['slack']['channel'], text=text)
        # assert response["message"]["text"] == "Hello world!"
    except SlackApiError as e:
        # You will get a SlackApiError if "ok" is False
        assert e.response["ok"] is False
        assert e.response["error"]  # str like 'invalid_auth', 'channel_not_found'
        print(f"Got an error: {e.response['error']}")
        # Also receive a corresponding status_code
        assert isinstance(e.response.status_code, int)
        print(f"Received a response status_code: {e.response.status_code}")

def get_sms():
    mngr = ModemManager.Manager.new_sync(
        Gio.bus_get_sync(Gio.BusType.SYSTEM, None),
        Gio.DBusObjectManagerClientFlags.DO_NOT_AUTO_START,
        None)
    obj = mngr.get_objects()[0]
    msg = obj.get_modem_messaging()
    recieved = msg.list_sync()
    for m in recieved:
        print(m.get_number(), m.get_timestamp(), '"%s"' % m.get_text())
        transfer_to_slack('From: ' + m.get_number() + "\n" + m.get_text())
        msg.delete_sync(m.get_path())

if __name__ == '__main__':
    while True:
        get_sms()
        time.sleep(config['general']['interval'])

