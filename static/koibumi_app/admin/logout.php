<?php
session_start();
$_SESSION = array(); // セッション情報をクリアする
session_destroy(); // セッションを終了する
setcookie("COOKIE_KOIBUMI", "", time() - 3600);
header('Location: index.php?message=ログアウトしました。'); // ログインページに遷移する
?>