<?php
include_once('_config.php');
define("PASSWORD", "$password");
    // HTMLエスケープ関数 <- 取得した任意のHTMLコードを実行する脆弱性に対処します
    function to_html($str){
      return htmlspecialchars($str, ENT_QUOTES|ENT_HTML5, "UTF-8");
  }

  //======= ログイン状況の確認 ==============

  if(isset($_SESSION['data'])){
      $login = true;
      $data = $_SESSION['data'];
  } elseif(isset($_SESSION["KOIBUMI_LOGIN"]) && $_SESSION["KOIBUMI_LOGIN"] != null && sha1(PASSWORD) === $_SESSION["KOIBUMI_LOGIN"]){
      $login = true;
  } else {
      $login = false;
  }

  // ログインしていない場合、ログインページに遷移
  if(!$login){
  header('Location: index.php?message=セッションの期限が終了したか、不正なアクセスです。');
      exit;
  }

  if(isset($_COOKIE["COOKIE_KOIBUMI"]) && $_COOKIE["COOKIE_KOIBUMI"] != ""){
    $_SESSION["KOIBUMI_LOGIN"] = $_COOKIE["COOKIE_KOIBUMI"];
}

  //======= ログイン状況の確認END ==============

include_once('inc/_core.php');
$koibumiAdm = new koibumi_admin();
?>
<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  <title>コイブミ管理画面<?php echo $subtitle; ?></title>
  <link rel="stylesheet" href="style.css">
  <link href="https://fonts.googleapis.com/icon?family=Material+Icons|Material+Icons+Round" rel="stylesheet">
</head>
<body>
<div id="container">
<header>
  <div id="header">
    <h1><a href="admin.php">コイブミ管理画面</a></h1>
    <form action="logout.php" method="post">
      <button type="submit" name="logout" id="logout">ログアウト</button>
    </form>
  </div>
    <?php if($password === 'pass') : ?>
    <div id="changepass">
      <p><span class="material-icons">warning</span> パスワードが初期設定のままです。設定変更ページから変更してください。</p>
    </div>
  <?php endif; ?>
</header>
