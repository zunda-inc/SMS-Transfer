#!/usr/bin/env python3
import json
import os
import time

from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

import gi
gi.require_version('ModemManager', '1.0')
from gi.repository import Gio, ModemManager


with open(os.path.join(os.path.dirname(__file__), 'config.json')) as f:
    config = json.load(f)

def post_to_slack(text):
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

def transfer():
    # sync dongle
    manager = ModemManager.Manager.new_sync(
        Gio.bus_get_sync(Gio.BusType.SYSTEM, None),
        Gio.DBusObjectManagerClientFlags.DO_NOT_AUTO_START, None)
    manager_objects = manager.get_objects()
    for manager_object in manager_objects:
        # check messages
        messaging = manager_object.get_modem_messaging()
        messages = messaging.list_sync()
          
        # post to slack each messages
        for message in messages:
            post_to_slack(f"{message.get_number()}\n{message.get_text()}")
            # delete message from dongle or sim
            messaging.delete_sync(message.get_path())

# start
if __name__ == '__main__':
    while True:
        transfer()
        time.sleep(config['general']['interval'])
