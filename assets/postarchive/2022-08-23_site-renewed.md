---
title: "サイトをリニューアルしました"
date: 2022-08-23T22:43:56+09:00
slug: "site-renewed"
draft: true
categories: [""]
tags: ["サイトについて"]
archives: ["2022-08", "2022"]
---
ふと思い立って、このサイトを一新しました。どんなふうに進めたか、勉強の記録も兼ねて書いてみます。

## イメージを書き出す

まずは、なんとなくこういう感じのサイトにしたいな、というイメージを図にしました。

{{< figure-image src="https://i.gyazo.com/94ea6b582465435f223a88abe20680a2.jpg" aspect="1x1" >}}
ノートにちまちまと手描き
{{< /figure-image >}}

そこから、構成要素を拾って言語化します。

- 1カラム
- 中央揃えでサイト名、その下に横並びでメニュー
- メニュー項目は、
  - サイトについて
  - ブログ
  - メモ
  - 問い合わせ窓口
- 最上部に（最下部にも？）お花の画像。端が見切れてる感じ
- トップページには「○○のサイトです」みたいな軽い説明と、ブログの最新記事のタイトルを3つくらい
- 問い合わせ窓口は必ず作る
- 全体的に優しい雰囲気
- 柔らかい黄緑か山吹色を使いたい
- リンクの文字色は青系

## 配色を決める

実作業に入る前に配色を決めることにしました。一から色を選んでいくセンスは持ち合わせていないので、既存の配色セットに頼ります。

#### 今回の条件

- 柔らかい色味
- 明度・彩度ともに高め
- 緑、黄色、水色を含む

『きれいな配色の本』に、条件にぴったり合うものがありました！

## HTMLを書く

最低限のタグだけを含むひな形を土台にして、上から順に、素直にHTMLを書いていきました。前のサイトをちまちまと手直ししていくより、まるごと書き直したほうが早そうだし、きれいにマークアップできそうな気がしたからです。一旦デザインのことは忘れて、簡素な骨組みだけを書きました。

ひな形は以下。DOCTYPE宣言やhtml要素など、今はどう書くのがいいんだっけ？　と悩むことが多いので、既存のものをありがたく使わせてもらっています。

- [ひな形のリンク]()

## 書いたHTMLをHugoのテーマファイルの形にする

このサイトは、Googleが提供するHugoという仕組みを使っているので、書いたHTMLをHugoが処理できるようになんやかんやする必要があります。このへん自分は全く詳しくないので細かくは書きません（というか書けません）が、以下の流れで進めました。

- Hugoでローカルにディレクトリを作る
- テーマは[blank]()をインストールして適用
- 先ほど書いたHTMLをblankテーマのpartialsに合わせて切り分けて、流し込む
- 必要に応じて記述をHugoの関数などに置き換える

## CSSを書く

イメージスケッチを見ながら、見た目を整えていきます。以前はSCSSを書いてHugoでコンパイルしていたんですけど、今回はCSSを書いて最後にminifyしてるだけです。よく考えたら自分はそんなに高度なことをしないので、CSSのVariablesやcalcを使えば間に合うなーと。

## トップページ以外を作る

ブログの記事一覧などなど、トップページ以外のページに着手。まずは素直に書いて、Hugoのプレビュー機能で確認しては修正、を繰り返していきました。