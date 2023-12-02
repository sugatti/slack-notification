#!/usr/bin/env python
# -*- coding: utf-8 -*-
import json
import logging
import os
from datetime import datetime
from dateutil import tz
from urllib.request import Request, urlopen
from textwrap import dedent


# 環境変数の読み込み
log_level = os.environ["LOG_LEVEL"]
web_hook = os.environ["WEBHOOK_URL"]
slack_channel = os.environ["SLACK_CHANNEL"]
slack_username = os.environ["SLACK_USERNAME"]

# loggerの初期設定
logger = logging.getLogger()
logger.setLevel(log_level)


def notify_slack(msgs, web_hook, slack_channel, slack_username):
    """
    slackにメッセージを投稿する
    Args:
        msgs(str): 投稿するメッセージ
        web_hook (str): 投稿するslackのwebhook URL
        slack_channel (str): 投稿するslackのチャンネル名
        slack_username (str): 投稿するslackのユーザ名
    """

    send_data = {
        "channel": slack_channel,
        "username": slack_username,
        "text": msgs
    }
    payload = "payload=" + json.dumps(send_data)
    request = Request(
        web_hook,
        data=payload.encode("utf-8"),
        method="POST"
    )

    with urlopen(request) as response:
        response_body = response.read().decode("utf-8")
    logger.info(f"response:  {response_body}")

    return response_body


def get_datetime_jst(dt: str) -> datetime:
    return datetime.strptime(
        dt, '%Y-%m-%dT%H:%M:%S.%f%z'
    ).astimezone(
        tz.gettz('Asia/Tokyo')
    )


def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))
    msg = json.loads(event["Records"][0]["Sns"]["Message"])
    err_msg = msg['messages'][0]  # Note: 2つ以上の要素が入ってきたことはないが、、、
    logger.info(f'msg: {msg}')

    if pipe_name := msg.get("pipeName"):
        table_name = msg["tableName"]
        timestamp = msg["timestamp"]
        timezone_jst = get_datetime_jst(timestamp)
        file_name = f'{msg["stageLocation"]}{err_msg["fileName"]}'
        err = err_msg["firstError"].replace("\n", " ")

        msg = dedent(
            f"""
            :warning: *Snowpipe Failed* :warning:
            ```
            Task       {pipe_name}
            Table      {table_name}
            File       {file_name}
            Timestamp  {timestamp}
                 (JST  {timezone_jst})
            Error      {err}
            ```
            """
        ).strip()

    elif task_name := msg.get("taskName"):
        timestamp = err_msg["completedTime"]
        timezone_jst = get_datetime_jst(timestamp)
        query_id = f'{err_msg["queryId"]}'
        err_code = f'{err_msg["errorCode"]}'
        err = err_msg["errorMessage"].replace("\n", " ")

        msg = dedent(
            f"""
            :warning: *Task Failed* :warning:
            ```
            タスク名: {task_name}
            クエリID: {query_id}
            終了時間: {timezone_jst}
            Error Code: {err_code}
            Error:   {err}
            ```
            """
        ).strip()
    logger.info(msg)

    try:
        notify_slack(msg, web_hook, slack_channel, slack_username)
        logger.info("Successful notification via slack")
    except Exception as e:
        logger.exception("Failed to notify slack: %s.", e)
        return "ng"

    return "ok"
    