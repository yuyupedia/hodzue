<?php
session_start();
$subtitle = 'TIPS | ';
include_once('inc/_header.php');
?>

<main>
  <?php include_once('inc/_sidebar.php'); ?>

  <div id="contents">
    <h2>TIPS</h2>
    <p>
      いいねボタン改の細かな運用方法を紹介しています。<br>
      いいねボタン利用の際に困ったことがあったらご参照ください。
    </p>

    <h3 id="sort_btn">管理画面でいいねボタン一覧を見やすくするTIPS</h3>
    <p>
      管理画面では、data-iinename属性に設定したボタン名が、数字→アルファベット→日本語の昇順となり、いいねボタンが一覧になっています。<br>
      いいねボタンを見やすく並べ替えたい場合は、data-iinename属性につける名前を工夫してみて下さい。<br>
      例：トップページは「000-トップページ」、作品ページにつけるいいねボタンは「101-作品１」「102-作品２」など
    </p>

    <h3 id="how_to_change_btnname">いいねボタンの名前を変更する方法</h3>
    <p>いいねボタンを設置しているHTMLファイルと、newiine_appフォルダ内のファイル名に変更を加える必要があります。</p>
    <ul>
      <li>いいねボタンを設置しているHTMLファイルを開き、<code>data-iinename</code>の値を新しい名前に変更する。変更前の<code>data-iinename</code>の値（旧名）を覚えておく</li>
      <li>いいねボタンを設置しているサイトのサーバーにFTP接続し、<code>newiine_app＞datas</code>を開く</li>
      <li><code>（いいねボタンの名前）.csv</code>というファイルがいくつか入っているので、旧名のついたCSVファイルの名前を、新しく設定した<code>data-iinename</code>の値に変更する（タイプミス防止のため、コピペ推奨）</li>
      <li>CSVファイルは、いいねボタンが初めてクリックされたときに自動で作成されるものです。もしも当該いいねボタンのCSVファイルが存在しない場合は、CSVファイルの名前変更作業は不要です</li>
    </ul>

    <h3 id="how_to_add_IP">いいねボタンをクリックした人のIPアドレスを調べる方法</h3>
    <p>管理画面からIPアドレスを確認することはできません。FTPツールを使ってサーバー上からデータファイルをダウンロードして確認を行います。</p>
    <ul>
      <li>いいねボタンを設置しているサイトのサーバーにFTP接続し、<code>newiine_app＞datas</code>を開く</li>
      <li><code>（いいねボタンの名前）.csv</code>というファイルがいくつか入っているので、いいねの記録を見たいボタンのCSVファイルをダウンロードする</li>
      <li>一行ごとに、<code>いいねボタンが設置されているURL,左記URLのページタイトル,<strong>クリックした人のIPアドレス</strong>,クリックした日付,左記日付のうち最終クリックした時刻,左記日付のうちにクリックした回数</code>が、半角コンマ(,)で区切って記録されている</li>
    </ul>

    <h3 id="how_to_delete_IP">いいねを拒否するIPアドレスを削除する方法</h3>
    <p>管理画面から削除することはできません。FTPツールを使ってサーバー上からデータファイルをダウンロードし、テキストエディタを使って直接ファイルを編集してください。</p>
    <ul>
      <li>いいねボタンを設置しているサイトのサーバーにFTP接続し、<code>newiine_app＞datas＞setting＞deny.dat</code>をダウンロードする</li>
      <li>拒否しているIPアドレスが１行に１つずつ記述されているので、拒否を解除したいIPアドレスを行ごと削除する</li>
      <li>書き換えたdeny.datを、サーバー上のdeny.datに上書きアップロードする</li>
    </ul>
    
  </form>

</div>
</main>

<?php include_once('inc/_footer.php'); ?>
