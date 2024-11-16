<?php
$getPassword = $_POST["password"];

    //ユーザーデータの取得
    include_once(dirname(__FILE__).'/inc/_config.php');
    define("PASSWORD", "$password");
    
    // パスワードの照合
    if($getPassword != PASSWORD){ // パスワードが一致しない場合
        header('Location: index.php?message=パスワードが間違っています。');
        exit;
    }

    // ログインOK
    session_start();
    $data = true;

    $_SESSION['data'] = $data; // ユーザ情報をセッション変数に格納
    $_SESSION["KOIBUMI_LOGIN"] = sha1(PASSWORD);//暗号化してセッションに保存
    setcookie("COOKIE_KOIBUMI", $_SESSION["KOIBUMI_LOGIN"], time()+3600*24*14);//暗号化してクッキーに保存
    header('Location: admin.php'); // メインページに遷移
    exit;
?>