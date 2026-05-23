import base64
import itertools
import json
import logging
import re
import shlex
from pypinyin import pinyin, Style
from fastapi import BackgroundTasks, FastAPI, HTTPException, Request
from aiogram import Bot
from aiogram.utils import formatting
from aiogram.types import BufferedInputFile
import requests
import os


bot_token = os.environ['BOT_TOKEN']
chat_id = int(os.environ['CHAT_ID'])
push_key = os.environ['PUSH_KEY']
self_url = os.environ['SELF_URL']
secret_token = os.environ['SECRET_TOKEN']
deployed_on_aliyun = False

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] {%(pathname)s:%(lineno)d} %(levelname)s - %(message)s',
    datefmt='%H:%M:%S'
)
app = FastAPI()

@app.api_route("/push", methods=['GET', 'POST'])
@app.api_route("/push/raw", methods=['GET', 'POST', 'PUT'])
async def push(request: Request):
    if request.url.path == "/push/raw":
        data = {
            'key': request.query_params.get('key'),
            'msg': b"Raw message handler received:\n" + await request.body(),
        }
    else:
        if request.method == 'POST':
            data = await request.json()
        elif request.method == 'GET':
            data = request.query_params

    if 'key' not in data or data['key'] != push_key:
        raise HTTPException(status_code=403, detail="invalid send key")
    
    try:
        async with Bot(token=bot_token) as bot:
            if 'type' not in data or data['type'] == 'text':
                ret = await bot.send_message(chat_id, data['msg'])
            elif data['type'] == 'image':
                ret = await bot.send_photo(chat_id, BufferedInputFile(base64.b64decode(data['msg']), filename='image'))
            elif data['type'] == 'markdown':
                ret = await bot.send_message(chat_id, data['msg'], parse_mode='MarkdownV2')
            elif data['type'] == 'file':
                ret = await bot.send_document(chat_id, BufferedInputFile(base64.b64decode(data['msg']), filename=data.get('filename', 'file')))
            else:
                msg = "invalid msg type. type should be text(default), image, markdown or file."
                raise HTTPException(status_code=400, detail=msg)

    except Exception as e:
        msg = "unexpected error: " + str(e)
        logging.exception(e)
        raise HTTPException(status_code=500, detail=msg)

    return {'message_id': ret.message_id}


@app.get("/tg/webhook_init")
async def webhook_init(request: Request):
    if request.query_params.get('token') != secret_token:
        raise HTTPException(status_code=403, detail="invalid token")

    async with Bot(token=bot_token) as bot:
        return await bot.set_webhook(url=f"{self_url}/tg/callback", secret_token=secret_token)


async def process(data):
    async with Bot(token=bot_token) as bot:
        try:
            if data['message']['from']['id'] != chat_id:
                raise Exception("invalid from chat id")
            
            logging.info("processing: " + data['message']['text'])
            user_id = data['message']['from']['id']

            msg = shlex.split(data['message']['text'])
            if msg[0] == "查询" or msg[0] == "拼音查询":
                response = ""
                re_expr = msg[1]
                results = []

                with open("nju.txt", "r") as f:
                    all_nju = f.readlines()
                counter = 0

                temp_msg = None

                for i in all_nju:
                    counter += 1
                    if msg[0] == "拼音查询" and counter % 10000 == 0:
                        if temp_msg is not None:
                            await bot.delete_message(user_id, temp_msg.message_id)
                        temp_msg = await bot.send_message(user_id, f"拼音查询中, 请稍后: {counter} / {len(all_nju)}")

                    def str2py(s, style):
                        if msg[0] != "拼音查询":
                            return ""

                        words = list(filter(lambda x: '集团' not in x and '大学' not in x and '学院' not in x and '用户' not in x and '未知' not in x, s.split(",")))

                        result = []
                        for w in words:
                            py = pinyin(w, errors='ignore', style=style, heteronym=True)
                            result.extend(list(itertools.product(*py)))
                        output = [''.join(item) for item in result]

                        return ',' + ','.join(output)

                    if re.search(re_expr, i.strip() + str2py(i, Style.NORMAL) + str2py(i, Style.FIRST_LETTER)) is not None:
                        results.append(i.strip())
                
                if temp_msg is not None:
                    await bot.delete_message(user_id, temp_msg.message_id)

                if len(msg) > 2:
                    page = int(msg[2]) - 1
                else:
                    page = 0

                for i in range(page * 5, (page + 1) * 5):
                    if i < len(results):
                        response += f"({i + 1}). {results[i]}\n"
                
                await bot.send_message(user_id, f"搜索结果(第{page + 1}页,共计{len(results)}条): \n" + response)
            else:
                await bot.send_message(user_id, "未知指令: " + msg[0])

        except Exception as e:
            logging.exception(e)
            await bot.send_message(chat_id, "Error processing message: \n> " + formatting.Text(json.dumps(data, ensure_ascii=False)).as_markdown() + "\nException: \n> " + formatting.Text(str(e)).as_markdown(), parse_mode='MarkdownV2')
            return "dropped"
    return "ok"


@app.post("/tg/callback")
async def callback(request: Request, background_tasks: BackgroundTasks):
    if request.headers.get('X-Telegram-Bot-Api-Secret-Token') != secret_token:
        raise HTTPException(status_code=403, detail="invalid token")

    data = await request.json()
    logging.info(data)

    if deployed_on_aliyun:
        r = requests.post(f"{self_url}/tg/process", json=data, headers={
            "X-Fc-Invocation-Type": "Async",
            "Token": secret_token
        })

        logging.info(r.text)
        if r.status_code != 202:
            raise HTTPException(status_code=500, detail="async process failed")
    else:
        background_tasks.add_task(process, data)

    return {"detail": "scheduled"}


@app.post("/tg/process")
async def process_req(request: Request):
    if request.headers.get('Token') != secret_token:
        raise HTTPException(status_code=403, detail="invalid token")
    
    data = await request.json()
    logging.info(data)
    
    return await process(data)
