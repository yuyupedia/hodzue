<?php
session_start();
$subtitle = '';
include_once('inc/_header.php');
?>

<main>
  <?php include_once('inc/_sidebar.php'); ?>

  <div id="contents">
    <h2>最近いいねされたボタン</h2>
    <p class="memo">今日もしくは昨日いいねされたボタンの一覧です。</p>

    <?php
    echo $newiineAdm->recentlyReport();
    ?>
  </form>

</div>
</main>

<?php include_once('inc/_footer.php'); ?>
