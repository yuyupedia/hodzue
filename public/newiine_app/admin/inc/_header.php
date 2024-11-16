<?php
include_once('_config.php');
define("PASSWORD", "$password");
$message = "";

if(isset($_COOKIE["COOKIE_NEWIINE"]) && $_COOKIE["COOKIE_NEWIINE"] != ""){
    $_SESSION["NEWIINE_LOGIN"] = $_COOKIE["COOKIE_NEWIINE"];
}

if(isset($_SESSION["NEWIINE_LOGIN"]) && $_SESSION["NEWIINE_LOGIN"] != null && sha1(PASSWORD) === $_SESSION["NEWIINE_LOGIN"]){
    $message = "Login success";
}else{
    session_destroy();  //セッション破棄
    header("Location:index.php");
}

include_once('inc/_core.php');
$newiineAdm = new newiine_admin();
?>
<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  <title><?php echo $subtitle; ?>いいねボタン改 管理画面</title>
  <link rel="stylesheet" href="style.css">
  <link href="https://fonts.googleapis.com/icon?family=Material+Icons|Material+Icons+Round" rel="stylesheet">
</head>
<body>
<div id="container">
<header>
  <div id="header">
    <h1><a href="admin.php">いいねボタン改 管理画面</a></h1>
    <form action="index.php" method="post">
      <button type="submit" name="logout" id="logout">ログアウト</button>
    </form>
  </div>
    <?php if($password === 'pass') : ?>
    <div id="changepass">
      <p><span class="material-icons">warning</span> パスワードが初期設定のままです。設定変更ページから変更してください。</p>
    </div>
  <?php endif; ?>
</header>
