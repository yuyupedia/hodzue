<?php
session_start();
ini_set( 'display_errors', 1 );
ini_set( 'error_reporting', E_ALL );
$subtitle = '';
include_once('inc/_header.php');
?>

<main>
  <?php include_once('inc/_sidebar.php'); ?>

  <div id="contents">
    <h2>最近１週間のメッセージ</h2>
    <?php include_once('inc/_selector.php'); ?>

    <?php
    echo $koibumiAdm->weeklyReport();
    ?>
  </form>

</div>
</main>

<?php include_once('inc/_footer.php'); ?>
