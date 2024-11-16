<?php

// ログイン処理　参考　https://qiita.com/keisuke-okb/items/7e7f25bd78705a06d5e0

    // HTMLエスケープ関数 <- 取得した任意のHTMLコードを実行する脆弱性に対処します
    function to_html($str){
      return htmlspecialchars($str, ENT_QUOTES|ENT_HTML5, "UTF-8");
  }

  $message = "";
  if(isset($_GET['message'])){
      $message = $_GET['message'];
  }

  //======= ログイン状況の確認 ==============
  session_start();
  include_once(dirname(__FILE__).'/inc/_config.php');
  define("PASSWORD", "$password");
  
  // クッキーの存在確認
  if(isset($_COOKIE["COOKIE_KOIBUMI"]) && $_COOKIE["COOKIE_KOIBUMI"] === sha1(PASSWORD)){

    $_SESSION["KOIBUMI_LOGIN"] = $_COOKIE["COOKIE_KOIBUMI"];
    header("Location:admin.php");

  }

  if(isset($_SESSION['data'])){
      $login = true;
      $data = $_SESSION['data'];
  } else {
      $login = false;
  }

  // すでにログインしている場合、メインページに遷移
  if($login){
      header('Location: admin.php');
      exit;
  }

  //======= ログイン状況の確認END ==============
?>
<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  <title>コイブミ管理ログイン</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="login">
  <p><?php echo to_html($message); ?></p>
    <form action="./login.php" method="post" enctype="multipart/form-data">
      <p><input name="password" type="password" value="" placeholder="パスワードを入力"> <button type="submit" value="submit" class="btn btn-primary">ログイン</button></p>
      <p style="font-size:12px;color:#a7a7a7;">一度ログインすると、14日間は自動でログインされるようになります。</p>
    </form>
  </div>
</body>
</html>
