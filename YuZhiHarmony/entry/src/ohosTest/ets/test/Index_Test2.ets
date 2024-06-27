import http from '@ohos.net.http';

@Entry
@Component
struct VoiceMessagePage {
  @State voiceMessage: string = '请录制语音...';
  @State lltmResponse: string = '';

  build() {
    Column() {
      Text('智语鸿蒙')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .padding({ top: '2%', bottom: '2%' })
        .width('81%')
        .textAlign(TextAlign.Center)
        .backgroundColor('#f5f5f5')
        .borderRadius(10)
        .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

      // 显示语音留言
      Column() {
        // 显示LLM回复
        Text(this.lltmResponse)
          .fontSize(18)
          .border({ width: 1, color: '#cccccc' })
          .padding('5%')
          .width('90%')
          .height('50%')
          .textAlign(TextAlign.Center)
          .borderRadius(10)
          .backgroundColor('#ffffff')
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

        // 显示语音留言
        Text(this.voiceMessage)
          .fontSize(18)
          .border({ width: 1, color: '#cccccc' })
          .padding('5%')
          .width('90%')
          .height('30%')
          .textAlign(TextAlign.Center)
          .borderRadius(10)
          .margin({ top: '3%' })
          .backgroundColor('#ffffff')
          .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });
      }
      .padding({ top: '5%', bottom: '5%', left: '5%', right: '5%' })
      .width('100%')
      .flexGrow(1);

      // 录音按钮
      Button('录制语音')
        .onClick(() => this.startRecording())
        .fontSize(18)
        .backgroundColor('#4CAF50')
        .width('60%')
        .height('10%')
        .alignSelf(ItemAlign.Center)
        .borderRadius(20)
        .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });

      // 发送按钮
      Button('发送')
        .onClick(() => this.sendMessage())
        .fontSize(18)
        .backgroundColor('#2196F3')
        .width('60%')
        .height('10%')
        .margin({ top: '2%' })
        .alignSelf(ItemAlign.Center)
        .borderRadius(20)
        .shadow({ color: '#000000', offsetX: 0, offsetY: 4, radius: 10 });
    }
    .height('100%')
    .width('100%')
    .padding({ left: '5%', right: '5%', top: '5%', bottom: '15%' })
    .backgroundColor('#e0e0e0');
  }

  startRecording() {
    this.voiceMessage = '正在录语音...';
    setTimeout(() => {
      this.voiceMessage = '已录制语音';
    }, 3000);
  }

  async sendMessage() {
    if (this.voiceMessage === '正在录语音...') {
      this.voiceMessage = '请先录制语音留言';
    } else {
      this.voiceMessage = '发送语音消息： ' + this.voiceMessage;
      this.lltmResponse = await this.callLLM(this.voiceMessage);
      console.log('发送语音消息:', this.voiceMessage);  // 添加日志
      setTimeout(() => {
        this.voiceMessage = '请录制语音';
      }, 2000);
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
