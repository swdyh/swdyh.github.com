theme: material
title: スタートアップでのRails開発/運用でやってよかったこと
author: @swdyh
cover: pictures/cover.png
lang: ja

## 自己紹介
- [github/swdyh](https://github.com/swdyh), [twitter/swdyh](https://twitter.com/swdyh)
- ブラウザ拡張 [AutoPagarize](http://autopagerize.net/) 作者
- Rails使いはじめて10年くらい
- 株式会社トレタ サーバサイドエンジニア


## トレタ
- 2013/07に会社設立したスタートアップ
- 飲食店向けの予約管理サービス
  - 飲食店の方が電話で予約を受けたときに入力するiPadアプリ
  - 予約から顧客データベースをつくり接客に利用
  - 飲食店の裏側をささえるサービス
- 4年、導入店舗9000店
- くわしくは [https://toreta.in/jp/feature/](https://toreta.in/jp/feature/)


## スタートアップ
- **プロダクト開発に集中**
- プロダクトにばかり集中しているとまわらなくなる
- プロダクト開発の合間に地道に運用面を整備していく
- あまり手間をかけずにそこそこ便利な仕組みをつくれるといい
- そういう視点をふまえて、やってよかったことをいくつか紹介します

## リクエストのログ
- Railsのログ、構造化されてなくて検索性が低い
  - 開発には便利だけど運用には別のログが必要
- アプリケーション固有のリクエストのログをつくる
   - HTTPの情報、URI, UA, IP, HTTPメソッド, レスポンスコード、処理時間
   - **リクエストID**
   - **アプリケーション固有のデータ**
     - トレタの例、ユーザID, 店舗ID, 予約ID, OAuthClientID


## リクエストID
- リクエストを一意に示すID
  - nginx(1.11.0以降)、X-Request-Idに[$request_id](http://nginx.org/en/docs/http/ngx_http_core_module.html#var_request_id)
  - [ActionDispatch::RequestId](http://api.rubyonrails.org/classes/ActionDispatch/RequestId.html) (Railsに入ってるRackMiddleware)
- 利用例
  - SQLのコメントに埋め込んでいる([Arproxy](https://github.com/cookpad/arproxy))。スロークエリーがどこで発生したかがすぐ分かる
- ちゃんと分散システムのトレーシングをしたいなら[X-Ray](https://aws.amazon.com/jp/xray/)/[Zipkin](http://zipkin.io/)とか
  - リクエストIDはもう少し手軽な追跡用途に


## ログの例
```
{
    "datetime":1510729796,
    "request_id":"ea196883-7f5a-4cb7-8133-8db73ca1f544",
    "request_uri":"/v1/restaurants.json",
    "account_id":1,
    "user_agent":"Staging1/15.0 (iPad; iOS 9.3.5; Scale/2.00)",
    "response_code":200,
    "response_time":0.10239052772521973 ....
```


## リクエストのログをどう作っているか
- かんたんなRackのミドルウェアで1行1JSONのログをファイルに出力
  - 標準のLoggerをフォーマットだけ変えて使用
- ↓から必要な情報を抜き出している
  - HTTPヘッダー
  - パラメータ
  - セッション
  - controllerインスタンスの変数


## リクエストのログを集めてためる
- たんにログをファイルに書いても使いにくいので集める
- SaaS([PaperTrail](https://papertrailapp.com/), [LogDNA](https://logdna.com/)とか)は、おおむねリテンション長いプランは高い
  - リテンションが短いと不便
- SaaSに比べれると少し手間はかかるけど、BigQueryがおすすめ
- BigQueryはログのためのものではないけれど、だからといって困ることもない


## BigQueryのいいところ
- [fluent-plugin-bigquery](https://github.com/kaizenplatform/fluent-plugin-bigquery)
- 従量課金、サービス成長に応じた料金
- 日付ごとにテーブルを分割しておいて、検索時に範囲指定できる
- index気にせず検索できる。正規表現、JSON関数、JavaScriptのUDF
- できるだけカラムと期間を絞る、それを心がけていれば、そんなに値段はいかない


## ジョブキューのログ1(Sidekiq)
- Railsのリクエストは基本的に同期処理なので、ジョブキュー処理が必須
- ジョブキューの処理ログもリクエストのログと同じくらい大事
- ジョブキューもいろいろあるけれど、RailsだとSidekiqがやっぱり便利
- これも同じように1行1JSONのログをファイルに書いて、fluentdでBQへ


## ジョブキューのログ2(Sidekiq)
- 処理時間を集計したり、抜けがないか確認したり
- Sidekiqのダッシュボードは便利だけど、処理が終わったものに関しては情報はほとんどない
- リクエストに比べて処理時間がユーザ体験に直結しないので見過ごしがち


## 定期処理
- 最初はcron -> [Sidekiq-Cron](https://github.com/ondrejbartas/sidekiq-cron)
- **リトライとかログとか複数台で動かすとか、全部Sidekiqまかせにできる**
- 定期処理になにを使っていても、実行もれに注意する
- 定期処理の処理開始/終了時にCloudWatchにping、pingの数をチェックしてアラート
- ジョブスケジューラ([kuroko2](https://github.com/cookpad/kuroko2), [rundeck](http://rundeck.org/)とか)も考えているが、Sidekiqが便利なのでしばらくはSidekiq-Cronの予定


## BigQuery活用
- DBの個人情報以外のカラムをBQへコピー
  - 社内用の分析、顧客用の分析、調査とか。
  - 調査時、ログの店舗IDやユーザIDとジョインしたりできて便利
- コピー方法は、自社ツールとembulk
  - 自社ツールはメモリ効率いい、メンテがちょっと面倒
- テーブルによっては、日毎のテーブルをコピーして残している
  - 分析用途で、日々変わってしまうデータをとっておきたかったりする


## ありがとうございました
- もっといい方法あるよとか、こんな工夫してるよ、とかおしえてください
