<?php
session_start();
$subtitle = ' | アーカイブ';
if(!empty($_GET["day"])) {
  $subtitle = ' | ' . $_GET["day"] .'デイリーレポート';
} elseif (!empty($_GET["month"])) {
  $subtitle = ' | ' . $_GET["month"] .'マンスリーレポート';
}
include_once('inc/_header.php');
?>

<main>
  <?php include_once('inc/_sidebar.php'); ?>

  <div id="contents">
    <?php if (!empty($_GET["day"])) : ?>
      <h2>デイリーレポート</h2>
      <?php include_once('inc/_selector.php'); ?>
      <?php
      $get_day = $_GET["day"];
      echo $koibumiAdm->dailyReport($get_day);
      elseif (!empty($_GET["month"])) :
        ?>
        <h2>マンスリーレポート</h2>
        <?php include_once('inc/_selector.php'); ?>

        <?php
        $month = $_GET["month"];
        echo $koibumiAdm->monthlyReport($month);
      endif; ?>
    </div>
  </main>

  <?php include_once('inc/_footer.php'); ?>
