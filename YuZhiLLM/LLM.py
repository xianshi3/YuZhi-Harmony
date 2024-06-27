import spacy
import speech_recognition as sr
from gtts import gTTS
import playsound
from flask import Flask, request, jsonify, render_template

# 加载spaCy模型
nlp = spacy.load("en_core_web_sm")

# 创建Flask应用
app = Flask(__name__)

# 语音识别函数
def recognize_speech_from_mic():
    recognizer = sr.Recognizer()
    with sr.Microphone() as source:
        print("请说出你的命令...")
        audio = recognizer.listen(source)
        try:
            transcription = recognizer.recognize_google(audio, language='zh-CN')
            print("你说: " + transcription)
            return transcription
        except sr.RequestError:
            print("API请求错误")
        except sr.UnknownValueError:
            print("无法理解的语音")
    return ""

# 解析命令并查找文档
def find_document(message):
    response = "对不起，我没有理解你的请求。"

    # 中文命令处理
    if "你好" in message or "您好" in message:
        response = "你好，有什么可以帮你的吗？"
    elif "帮助" in message or "帮我" in message:
        response = "当然，请告诉我你需要什么帮助。"
    elif "查找 Open Harmony 开发文档" in message:
        response = ("OpenHarmony开源项目 项目介绍：OpenHarmony是由开放原子开源基金会（OpenAtom Foundation）孵化及运营的开源项目，"
                    "目标是面向全场景、全连接、全智能时代，基于开源的方式，搭建一个智能终端设备操作系统的框架和平台，"
                    "促进万物互联产业的繁荣发展。")
    elif "查找" in message or "寻找" in message or "找" in message:
        response = "你想查找什么？请详细说明。"
    elif "谢谢" in message or "感谢" in message:
        response = "不用谢，这是我应该做的。"
    elif "天气" in message:
        response = "今天的天气很好，适合出去散步。"
    elif "时间" in message:
        from datetime import datetime
        now = datetime.now()
        response = f"现在的时间是 {now.strftime('%Y年%m月%d日 %H:%M:%S')}"
    elif "笑话" in message:
        response = "你知道吗？计算机为什么喜欢看海？因为它们喜欢追踪信息流！"
    elif "计算" in message:
        try:
            expression = message.split('计算')[-1].strip()
            result = eval(expression)
            response = f"结果是 {result}"
        except:
            response = "对不起，我无法计算这个表达式。"

    # 英文命令处理
    elif "hello" in message.lower():
        response = "Hello, how can I help you?"
    elif "help" in message.lower():
        response = "Sure, please tell me what you need help with."
    elif "find Open Harmony documentation" in message.lower():
        response = ("OpenHarmony is an open source project incubated and operated by the OpenAtom Foundation. "
                    "It aims to build a framework and platform for smart terminal device operating systems "
                    "based on open source methods, promoting the prosperity of the Internet of Everything industry.")
    elif "find" in message.lower() or "search" in message.lower() or "look for" in message.lower():
        response = "What are you looking for? Please specify."
    elif "thank you" in message.lower() or "thanks" in message.lower():
        response = "You're welcome, that's what I'm here for."
    elif "weather" in message.lower():
        response = "The weather is great today, perfect for a walk."
    elif "time" in message.lower():
        from datetime import datetime
        now = datetime.now()
        response = f"The current time is {now.strftime('%Y-%m-%d %H:%M:%S')}"
    elif "joke" in message.lower():
        response = "Why do computers like to watch the ocean? Because they love tracking the data flow!"
    elif "calculate" in message.lower():
        try:
            expression = message.split('calculate')[-1].strip()
            result = eval(expression)
            response = f"The result is {result}"
        except:
            response = "Sorry, I can't calculate that expression."

    return response

# 处理命令的API端点
def speak(text):
    tts = gTTS(text=text, lang='zh')
    tts.save("response.mp3")
    playsound.playsound("response.mp3")

@app.route('/api/command', methods=['POST'])
def handle_command():
    try:
        data = request.json
        print(f"接收到数据: {data}")  # 记录接收到的数据
        message = data.get('command', '')  # 这里更改为从'data'中获取'command'字段
        print(f"接收到命令: {message}")  # 记录接收到的命令
        result = find_document(message) if message else "请提供有效的命令。"
        print(f"返回结果: {result}")  # 记录返回的结果
        # speak(result)  # 调用文本转语音功能
        return jsonify({"response": result})  # 确保JSON响应包含'response'字段
    except Exception as e:
        print(f"处理命令时出错: {e}")
        return jsonify({"response": "服务器内部错误"}), 500

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
