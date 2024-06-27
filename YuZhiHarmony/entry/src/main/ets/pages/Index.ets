import http from '@ohos.net.http';
import audio from '@ohos.multimedia.audio';
import fileio from '@ohos.fileio';
import buffer from '@ohos.buffer';

@Entry
@Component
struct VoiceMessagePage {
  @State voiceMessage: string = '请录制语音';
  @State lltmResponse: string = ''; // 用户文本输入状态
  @State userInput: string = ''; // 用户文本输入状态
  audioCapturer: audio.AudioCapturer | null = null; // 录音对象
  audioFilePath: string = '/data/accounts/account_0/appdata/voiceMessage.wav'; // 音频文件保存路径

  build() {
    Column() {

      // 显示LLM响应或提示用户录音或输入文本
      Text('智语LLM大模型-智语鸿蒙测试面板')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .padding({ top: '1%', bottom: '1%' })
        .width('90%')
        .textAlign(TextAlign.Center)
        .backgroundColor('#f5f5f5')
        .borderRadius(10)
        .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

      // 显示录音状态信息
      Column() {
        Text(this.lltmResponse || 'LLM没获取到内容请发送录制的语音或输入文本')
          .fontSize(18)
          .border({ width: 1, color: '#cccccc' })
          .padding('5%')
          .width('100%')
          .height('50%')
          .textAlign(TextAlign.Center)
          .borderRadius(10)
          .backgroundColor('#ffffff')
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

        // 用户输入文本框
        Text(this.voiceMessage)
          .fontSize(18)
          .border({ width: 1, color: '#cccccc' })
          .width('100%')
          .height('15%')
          .textAlign(TextAlign.Center)
          .borderRadius(10)
          .margin({ top: '3%' })
          .backgroundColor('#ffffff')
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

        TextInput({ placeholder: '输入文本信息', text: this.userInput })
          .onChange((value: string) => {
            this.userInput = value;
          })
          .fontSize(18)
          .padding({ top: '2%', bottom: '2%' })
          .width('120%')
          .height('20%')
          .borderRadius(10)
          .margin({ top: '3%' })
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });
      }
      .padding({ top: '2%', bottom: '5%', left: '5%', right: '5%' })
      .width('100%')
      .flexGrow(1);

      // 录音、停止录音、发送语音、发送文本按钮
      Row() {
        Button('录制语音')
          .onClick(() => this.startRecording())
          .fontSize(18)
          .backgroundColor('#4CAF50')
          .width('20%')
          .height('10%')
          .borderRadius(20)
          .margin({ top: '-2%' })
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

        Button('停止录音')
          .onClick(() => this.stopRecording())
          .fontSize(18)
          .backgroundColor('#F44336')
          .width('20%')
          .height('10%')
          .margin({ left: '2%', top: '-2%' })
          .borderRadius(20)
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

        Button('发送语音')
          .onClick(() => this.sendVoiceMessage())
          .fontSize(18)
          .backgroundColor('#2196F3')
          .width('20%')
          .height('10%')
          .margin({ left: '2%' , top: '-2%'})
          .borderRadius(20)
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

        Button('发送文本')
          .onClick(() => this.sendTextMessage())
          .fontSize(18)
          .backgroundColor('#FF9800')
          .width('20%')
          .height('10%')
          .margin({ left: '2%', top: '-2%' })
          .borderRadius(20)
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });
      }
      .alignSelf(ItemAlign.Center);
    }
    .height('100%')
    .width('100%')
    .padding({ left: '5%', right: '5%', top: '2%', bottom: '8%' })
    .backgroundColor('#e0e0e0');
  }

  // 开始录音操作
  async startRecording(): Promise<void> {
    this.voiceMessage = '正在录语音中';

    const audioStreamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
      channels: audio.AudioChannel.CHANNEL_2,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    };

    const audioCapturerInfo: audio.AudioCapturerInfo = {
      source: audio.SourceType.SOURCE_TYPE_MIC,
      capturerFlags: 0
    };

    const audioCapturerOptions: audio.AudioCapturerOptions = {
      streamInfo: audioStreamInfo,
      capturerInfo: audioCapturerInfo
    };

    try {
      this.audioCapturer = await audio.createAudioCapturer(audioCapturerOptions);

      if (this.audioCapturer) {
        this.audioCapturer.start();
        this.voiceMessage = '已开始录制语音留言。';
      } else {
        console.error('创建 AudioCapturer 对象失败');
        this.voiceMessage = '录音失败';
      }
    } catch (error) {
      console.error('录音时出错：', error);
      this.voiceMessage = '录音失败';
    }
  }

  // 停止录音操作
  stopRecording() {
    if (this.audioCapturer) {
      this.audioCapturer.stop();
      this.audioCapturer.release();
      this.audioCapturer = null;
      this.voiceMessage = '录音已停止';
    }
  }

  // 发送录制的语音消息
  async sendVoiceMessage() {
    if (this.voiceMessage === '正在录语音') {
      this.voiceMessage = '请先录制语音留言';
    } else {
      this.voiceMessage = '发送语音消息： ' + this.voiceMessage;
      const audioData = await this.readAudioFile();
      if (audioData) {
        const recognizedText = await this.recognizeSpeech(audioData);
        this.lltmResponse = await this.callLLM(recognizedText || this.voiceMessage);
      } else {
        this.lltmResponse = '读取音频文件失败';
      }
      setTimeout(() => {
        this.voiceMessage = '请录制语音';
      }, 2000);
    }
  }

  // 发送用户输入的文本消息
  async sendTextMessage() {
    if (this.userInput.trim() === '') {
      this.lltmResponse = '请输入文本信息';
    } else {
      const response = await this.callLLM(this.userInput);
      if (response) {
        this.lltmResponse = response;
      } else {
        this.lltmResponse = '没获取到内容请发送录制的语音或输入文本';
      }
      this.userInput = ''; // 清空文本输入框
    }
  }

  // 读取录制的音频文件
  async readAudioFile(): Promise<string> {
    try {
      const fd = await fileio.open(this.audioFilePath, 0);
      const stat = await fileio.fstat(fd);
      const byteArray = new Uint8Array(stat.size);
      await fileio.read(fd, byteArray, { offset: 0, length: stat.size, position: 0 });
      await fileio.close(fd);
      return buffer.from(byteArray).toString('base64');
    } catch (error) {
      console.error('读取音频文件出错：', error);
      return '';
    }
  }

  // 调用语音识别API识别语音内容
  async recognizeSpeech(audioData: string): Promise<string> {
    const apiKey = 'YOUR_API_KEY'; // 替换为实际的API密钥
    const apiUrl = 'YOUR_SPEECH_RECOGNITION_API_URL'; // 替换为实际的语音识别API URL

    const requestData = {
      audio: audioData,
      encoding: 'WAV',
      languageCode: 'zh-CN'  // 使用中文进行语音识别
    };

    const httpRequest = http.createHttp();
    const options = {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
      extraData: JSON.stringify(requestData)
    };

    try {
      const response = await httpRequest.request(apiUrl, options);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string);
        return result.transcription;
      } else {
        console.error('语音识别请求失败：', response.responseCode);
        return '';
      }
    } catch (error) {
      console.error('语音识别出错：', error);
      return '';
    }
  }

  // 调用LLM进行自然语言处理
  async callLLM(message: string): Promise<string> {
    const apiKey = 'YOUR_API_KEY'; // 替换为实际的LLM API URL
    const apiUrl = 'https://d4bb-171-37-43-218.ngrok-free.app/api/command'; // 替换为实际的LLM API密钥

    const requestData = { message: message };
    const httpRequest = http.createHttp();
    const options = {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
      extraData: JSON.stringify(requestData)
    };

    try {
      const response = await httpRequest.request(apiUrl, options);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string);
        return result.response;
      } else {
        console.error('LLM 请求失败：', response.responseCode);
        return '';
      }
    } catch (error) {
      console.error('调用 LLM 出错：', error);
      return '';
    }
  }
}
