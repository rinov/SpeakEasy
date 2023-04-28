# 英会話学習アプリ - SpeakEasy

このアプリは、英会話の練習を目的としたiOSアプリです。音声入力にSFSpeechRecognizerを利用し、音声出力にAWS Pollyを使用し、会話のレスポンス生成にはChatGPT-3.5を活用しています。アーキテクチャはMVVMで、SwiftUIで構築しています。


# 機能

- 音声入力による英語の発話練習
- AIによる英会話応答生成
- AWS Pollyを使用した音声出力
- 会話のコンテキストのの保存

# インストール方法

1. Xcodeをインストールし、最新バージョンにアップデートしてください。(XCode14以上)
2. リポジトリをクローンまたはダウンロードします。
3. Xcodeでプロジェクトファイル（SpeakEasy.xcworkspace）を開きます。
4. 必要なライブラリやAPIキーをセットアップします（credential.plistに記載）。
5. 実機でアプリをビルド＆実行します。

# APIキーのセットアップ

本プロジェクトでは `credential.plist`から秘匿情報を取得します。このファイル名は.gitignoreに登録されているためcommitされないようになっています。
ファイルの作成方法はプロジェクトルートでXCode上から新規ファイル追加でPropertyListを選択し、以下のキー名で登録を行なってください。

OpenAI API Key: `OPENAI_API_KEY`
AWS Access Key: `AWS_ACCESS_KEY`
AWS Secret Key: `AWS_SECRET_KEY`

# 使用方法
アプリを起動すると、最初に一度音声入力の許諾ダイアログが表示されるためこれを許可します。すると、以降はアプリを立ち上げた時点から音声入力を行うことができ、入力した内容によって英会話の練習ができます。アプリはユーザーの音声を認識し自動でテキスト変換し、これによってAIのレスポンスを生成し音声で再生します。

# ライセンス
このアプリはMIT Licenseのもとで公開されています。詳細については、LICENSEファイルを参照してください。
