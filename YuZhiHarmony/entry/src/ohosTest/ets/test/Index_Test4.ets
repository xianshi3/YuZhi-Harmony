import http from '@ohos.net.http';
import audio from '@ohos.multimedia.audio';
import fileio from '@ohos.fileio';
import buffer from '@ohos.buffer';

@Entry
@Component
struct VoiceMessagePage {
  @State voiceMessage: string = '请录制语音...';
  @State lltmResponse: string = '';
  audioCapturer: audio.AudioCapturer;
  audioFilePath: string = '/data/accounts/account_0/appdata/voiceMessage.wav';

  build() {
    Column() {
      Text('智语LLM大模型-智语鸿蒙测试面板')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .padding({ top: '2%', bottom: '2%' })
        .width('95%')
        .textAlign(TextAlign.Center)
        .backgroundColor('#f5f5f5')
        .borderRadius(10)
        .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

      Column() {
        Text(this.lltmResponse || '没获取到内容请发送录制的语音')
          .fontSize(18)
          .border({ width: 1, color: '#cccccc' })
          .padding('5%')
          .width('105%')
          .height('50%')
          .textAlign(TextAlign.Center)
          .borderRadius(10)
          .backgroundColor('#ffffff')
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

        Text(this.voiceMessage)
          .fontSize(18)
          .border({ width: 1, color: '#cccccc' })
          .padding('5%')
          .width('105%')
          .height('30%')
          .textAlign(TextAlign.Center)
          .borderRadius(10)
          .margin({ top: '3%' })
          .backgroundColor('#ffffff')
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

      }
      .padding({ top: '2%', bottom: '5%', left: '5%', right: '5%' })
      .width('100%')
      .flexGrow(1);

      Row() {
        Button('录制语音')
          .onClick(() => this.startRecording())
          .fontSize(18)
          .backgroundColor('#4CAF50')
          .width('30%')
          .height('10%')
          .borderRadius(20)
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

        Button('停止录音')
          .onClick(() => this.stopRecording())
          .fontSize(18)
          .backgroundColor('#F44336')
          .width('30%')
          .height('10%')
          .margin({ left: '2%' })
          .borderRadius(20)
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

        Button('发送')
          .onClick(() => this.sendMessage())
          .fontSize(18)
          .backgroundColor('#2196F3')
          .width('30%')
          .height('10%')
          .margin({ left: '2%' })
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

  async startRecording(): Promise<void> {
    this.voiceMessage = '正在录语音...';

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
        this.audioCapturer.start((err, data) => {
          if (err) {
            console.error('录音时出错：', err);
            this.voiceMessage = '录音失败';
          } else {
            this.voiceMessage = '已录制语音留言。';
          }
        });
      } else {
        console.error('创建 AudioCapturer 对象失败');
        this.voiceMessage = '录音失败';
      }
    } catch (error) {
      console.error('录音时出错：', error);
      this.voiceMessage = '录音失败';
    }
  }

  stopRecording() {
    if (this.audioCapturer) {
      this.audioCapturer.stop();
      this.audioCapturer.release();
    }
  }

  async sendMessage() {
    if (this.voiceMessage === '正在录语音...') {
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

  async recognizeSpeech(audioData: string): Promise<string> {
    const httpRequest = http.createHttp();
    const url = ''; // 替换LLM API端点
    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': '' // 替换为您的API密钥
      },
      extraData: JSON.stringify({
        audio: audioData,
        format: 'wav'
      })
    };

    try {
      const response = await httpRequest.request(url, options);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string);
        return result.transcript || '';
      } else {
        console.error('语音识别API调用失败：', response);
        return '';
      }
    } catch (error) {
      console.error('调用语音识别API出错：', error);
      return '';
    }
  }

  async callLLM(message: string): Promise<string> {
    const httpRequest = http.createHttp();
    const url = 'http://10.202.17.38:5000/api/command'; // 替换LLM服务器地址
    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json'
      },
      extraData: JSON.stringify({
        command: message
      })
    };

    try {
      const response = await httpRequest.request(url, options);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string);
        console.log('LLM API 调用成功：', result);  // 添加日志
        return result.response || '未找到相关文档';
      } else {
        console.error('LLM API 调用失败：', response);
        return 'LLM API 调用失败';
      }
    } catch (error) {
      console.error('调用 LLM API 出错：', error);
      return '调用 LLM API 出错';
    }
  }
}
