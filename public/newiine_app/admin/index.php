<?php
session_start();
include_once(dirname(__FILE__).'/inc/_config.php');
define("PASSWORD", "$password");
$message = '';
$loginURL = 'admin.php';

if(isset($_POST['logout'])) {
  $message = 'logout';
}

//クッキーの存在確認
if(isset($_COOKIE["COOKIE_NEWIINE"]) && $_COOKIE["COOKIE_NEWIINE"] === sha1(PASSWORD)){

    $_SESSION["NEWIINE_LOGIN"] = $_COOKIE["COOKIE_NEWIINE"];
    header("Location:$loginURL");

}

if(isset($_POST["action"])&&$_POST["action"]==="login"){
    if(PASSWORD === $_POST["password"]){//パスワード確認

      $_SESSION["NEWIINE_LOGIN"] = sha1(PASSWORD);//暗号化してセッションに保存

        if(isset($_POST["memory"]) && $_POST["memory"]==="true"){//次回からは自動的にログイン
          setcookie("COOKIE_NEWIINE", $_SESSION["NEWIINE_LOGIN"], time()+3600*24*14);//暗号化してクッキーに保存
        }

        header("Location:$loginURL");

    }else{
        session_destroy();//セッション破棄
        $message = 'notmatch';
    }
} elseif(isset($_POST['logout'])) {
    setcookie("COOKIE_NEWIINE", "", time() - 3600);
    session_destroy();  //セッション破棄
    $message = 'logout';
} elseif(isset($_GET['mode']) && $_GET['mode'] === 'logout') {
  $message = 'changepass';
}
?>
<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  <title>いいねボタン改 管理ログイン</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>

    <?php
    if($message === 'notmatch'){
      print '<p class="loginmessage alert">パスワードが違います。</p>';
    } elseif ($message === 'logout'){
      print '<p class="loginmessage logout">ログアウトしました。</p>';
    } elseif ($message === 'changepass'){
      print '<p class="loginmessage logout">パスワードを変更しました。<br>新しいパスワードでログインし直してください。</p>';
    }
    ?>
    <div class="login">
      <form action="" method="post">
        <p><input name="password" type="password" value="" /><input name="action" type="submit" value="login" /></p>
        <p><label><input type="checkbox" name="memory" value="true" />次回からは自動的にログイン</label></p>
      </form>
    </div>


</body>
</html>
