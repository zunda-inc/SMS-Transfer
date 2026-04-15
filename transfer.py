#!/usr/bin/env python3
import json
import logging
import os
import signal
import sys
import time

import gi
gi.require_version('ModemManager', '1.0')
from gi.repository import Gio, ModemManager

from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger(__name__)


def _load_config():
    path = os.path.join(os.path.dirname(__file__), 'config.json')
    with open(path) as f:
        cfg = json.load(f)
    required = [("slack", "token"), ("slack", "channel"), ("general", "interval")]
    for section, key in required:
        if not cfg.get(section, {}).get(key):
            raise ValueError(f"Missing config: {section}.{key}")
    return cfg


config = _load_config()


def _handle_signal(sig, frame):
    logger.info("Received signal %s, shutting down.", sig)
    sys.exit(0)

signal.signal(signal.SIGTERM, _handle_signal)
signal.signal(signal.SIGINT, _handle_signal)


def post_to_slack(text):
    client = WebClient(token=config['slack']['token'])
    try:
        client.chat_postMessage(channel=config['slack']['channel'], text=text)
    except SlackApiError as e:
        logger.error("Slack API error: %s (status %s)", e.response.get("error"), e.response.status_code)
        raise


def transfer():
    try:
        manager = ModemManager.Manager.new_sync(
            Gio.bus_get_sync(Gio.BusType.SYSTEM, None),
            Gio.DBusObjectManagerClientFlags.DO_NOT_AUTO_START, None)
        manager_objects = manager.get_objects()
        for manager_object in manager_objects:
            messaging = manager_object.get_modem_messaging()
            messages = messaging.list_sync()
            for message in messages:
                number = message.get_number()
                text = message.get_text()
                logger.info("SMS received from %s, Message: %s", number, text)
                try:
                    post_to_slack(f"{number}\n{text}")
                    messaging.delete_sync(message.get_path())
                    logger.info("Message forwarded and deleted.")
                except SlackApiError:
                    logger.warning("Slack post failed — message kept on dongle for retry.")
    except Exception:
        logger.exception("Error during transfer()")


if __name__ == '__main__':
    logger.info("SMS Transfer service starting.")
    while True:
        transfer()
        time.sleep(config['general']['interval'])
