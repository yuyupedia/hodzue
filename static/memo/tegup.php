<?php

# ================================================================== #
#  てがろぐ本体お手軽アップデータ TegUp Ver 1.0.0       [tegup.php]  #
# ================================================================== #
#  Copyright (C) Fumihiro Nishimura.(Nishishi) 2024.                 #
#                                                                    #
#  てがろぐをワンクリックで最新版にバージョンアップできるPHPスクリプ #
#  トです。既に最新版が稼働している場合には何もしません。投稿データ  #
#  や設定を誤って上書きしてしまう心配なくバージョンアップできます。  #
#                                                                    #
#  既存のパーミッション値を維持するほか、tegalog.cgi ファイルの冒頭  # 
#  で設定された各種設定値を維持して(引き継いで)バージョンアップでき  #
#  ます。（そのため、新規のセットアップには使えません。）            #
#                                                                    #
#  この tegup.php は、tegalog.cgi の存在するディレクトリと同じ位置に #
#  置いた上で、てがろぐCGIにログインしている状態のブラウザでアクセス #
#  してお使い下さい。(非ログイン状態でも使用可能にしたい場合は、設定 #
#  値を変更して下さい。)                                             #
#                                                                    #
#  ※TegUpの動作には、PHP 5.2.0 以上が必要で、かつ ZipArchive クラス #
#  　が使用可能である必要があります。                                #
#                                                                    #
#  https://www.nishishi.com/                           [2024/08/05]  #
# ================================================================== #

// ―――――――――――――――――――――――――――
// ▼ユーザ設定項目群
// ―――――――――――――――――――――――――――

// ●てがろぐ本体ファイル名（※デフォルトでは tegalog.cgi ですが、変更している場合は変更後のファイル名を指定して下さい。編集する際には、引用符を消さないようにご注意下さい。）
$tegalogFileName = 'tegalog.cgi';

// ※(↑編集時の注意↑) 一括置換機能等は使わずに、上記1点だけのファイル名を書き換えて下さい。このPHPソース内には他に 'tegalog.cgi' の記述が登場しますが、それらを書き換えてしまうと正しく動作しなくなります。

// ●このツールの使用を許可するユーザ権限 (0～9)
// 　　9 : てがろぐ側で管理者権限(Lv.9)のあるユーザがログインしている場合だけに実行を許可 (※デフォルト)
// 　　7 : てがろぐ側で編集者権限(Lv.7)以上のユーザがログインしている場合に実行を許可
// 　　1 : 権限は問わず、誰かがログインさえしていれば実行を許可
// 　　0 : ログインしていなくても実行を許可
$requiredUserLv = 9;

// ●バージョンアップ作業の直前に実行するバックアップの対象ファイル
// 　　0 : バックアップしない (非推奨)
// 　　1 : てがろぐ本体2ファイルだけをバックアップ (標準)
// 　　2 : てがろぐ本体に加えて、パスワード・セッションID保存ファイルと、設定ファイル、データファイルも含めた5ファイルをバックアップ
$backupTargets = 1;

// ●作業用として一時的に作成する仮ディレクトリのパーミッション (※8進数で指定するため先頭に 0 が必須)
$tempDirPermission = 0755;

// ●作業ログをファイル(tegup.log)にも出力するかどうか
// 　　0 : 出力しない (標準)
// 　　1 : 出力する (※動作がうまくいかない場合で、作業ログを画面上で確認できない場合には、こちらを試してみて下さい。※問題が解決した後は、値を 0 に戻して、ログファイル tegup.log を削除して下さい。)
$outputLogToFile = 0;


// ―――――――――――――――――――――――――――
// ▼設定項目群（※変更は非推奨！）
// ―――――――――――――――――――――――――――

// てがろぐCGIソース内から探して抽出する設定値の変数名群
// 　　※将来に、てがろぐ側の仕様が変更されて「維持すべき設定値の数」が変化した場合に備えるための設定項目です。仕様が変わらない限り、書き換えないで下さい。
// 　　※今のところ13個。
$setVals = array(
	'bmsdata' ,
	'setfile' ,
	'passfile' ,
	'autobackupto' ,
	'imagefolder' ,
	'keepsession' ,
	'safemode' ,
	'nopassuser' ,
	'safessi' ,
	'charcode' ,
	'skincover' ,
	'skininside' ,
	'howtogetpath'
);

// ―――――――――――――――――――――――――――
// ▲設定はここまで ／これ以下は書き換えずにご使用下さい。
// ―――――――――――――――――――――――――――

// ----------------------
// ランダムな英数字を生成		引数:個数(省略したら1)、返値:生成した英数字文字列
// ----------------------
function genRandStr($num = 1)
{
	$chars = 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';	// 数字の割合をちょっと多めに。
	$length = strlen($chars);
	$result = '';

	for ($i = 0; $i < $num; $i++) {
		$randomChar = $chars[rand(0, $length - 1)];
		$result .= $randomChar;
	}
	return $result;
}

// ---------------------------
// 指定URLのアクセス可否を確認		引数:URL、返値:1=可能/0:不可/-1:失敗
// ---------------------------
function checkExistUrl($url)
{
	$httpHeaders = get_headers($url);
	if( $httpHeaders ) {
		// 何か返ってくれば、中身を調べる
		if( strpos($httpHeaders[0], '200') !== false) {
			// HTTPステータスコード200が含まれていればアクセス可能とする (本来のコードの他に200という文字列が含まれているようなケースは面倒なので考慮しない。アクセス先はうちのサイトだけのハズだから。)
			return 1;
		}
		else {
			// 他のステータスコードならアクセス不可
			return 0;
		}
	}
	return -1;
}

// -----------------
// ZIPファイルを展開	引数1:ZIPファイル名、引数2:展開先DIR、返値:1=成功/-1:失敗
// -----------------
function extractZip($zipFile, $extractDir)
{
	$zip = new ZipArchive;
	if( $zip->open($zipFile) === true ) {
		$zip->extractTo($extractDir);
		$zip->close();
		return 1;
	}
	return -1;
}

// -----------------
// ZIPファイルに圧縮	引数1:対象ファイルパス群(配列)、引数2:保存ZIPファイル名、返値:圧縮されたファイル数/-1:失敗
// -----------------
function archiveZip($targets, $zipFile)
{
	$zip = new ZipArchive();
	$counter = 0;
	if($zip->open( $zipFile, ZipArchive::CREATE ) === true) {
		// 指定されたファイルをZIPに追加
		foreach( $targets as $one ) {
			if (file_exists($one)) {
				$zip->addFile($one, basename($one));	// ディレクトリは排除してファイル名だけでZIPに格納
				$counter++;
			}
			else {
				errorMsg('圧縮対象ファイル ' . htmlsafe($one) . ' は存在しません。スキップしました。');
			}
		}
		$zip->close();
		return $counter;
	}
	else {
		return -1;
	}
}

// ----------------------------------
// てがろぐの最新バージョン番号を得る		引数:リリース種別(official/beta等)、返値:バージョン番号文字列(該当がなければ空文字列、アクセス不可なら-1)
// ----------------------------------
function getTegalogLatestVer($releaseType = 'official')
{
	$infoUrl = 'https://www.nishishi.com/cgi/tegalog/info/latestversion.php?type=ini';
	if( checkExistUrl($infoUrl) < 1 ) {
		// アクセスできなかった場合
		errorEnd('<p>てがろぐCGIの最新バージョン番号の取得に失敗しました。</p><p>以下の可能性があります。</p><ul><li><a href="https://www.nishishi.com/">作者のウェブサイト</a>が落ちている。（この場合は、復活を待ってから再度実行して下さい。）</li><li>何らかの保守作業中で情報公開が停止している。（アナウンスを探すか、しばらく待ってから再度試して下さい。）</li><li>当ツール「TegUp」が古くなっている。（新しいバージョンを探して差し替えて下さい。）</li></ul>');
		exit;
	}
	$infoData = file_get_contents($infoUrl);

	// 種別とバージョン情報を格納する連想配列
	$versions = [];

	// 種別ごとのバージョン番号を連想配列に格納する
	if($infoData !== false) {
		$lines = explode("\n", $infoData);
		foreach ($lines as $line) {
			$parts = explode('=', $line);
			if (count($parts) === 2) {
				$relType = trim($parts[0]);
				$appVersion = trim($parts[1]);
				$versions[$relType] = $appVersion;
			}
		}
	}
	else {
		// アクセスできなかった場合
		return -1;
	}

	// 指定のリリース種別に対するバージョン番号があれば返す
	if( isset($versions[$releaseType]) ) {
		return $versions[$releaseType];
	}
	else {
		return '';
	}
}

// --------------------------------------
// 変数定義文字列の中に初期値があれば返す		引数:対象文字列、返値:定義値(引用符があれば消して返す)／なければfalse
// --------------------------------------
function getInitialValue($line)
{
	// イコール記号の右側かつセミコロン記号の左側で、空白以外の文字列を得る
	if(preg_match("/^.+=\s*(\S+)\s*;/", $line, $firstMatches)) {
		// 得られたら
		$eqright = $firstMatches[1];

		// 引用符に囲まれている場合は中身だけを得る
		if(preg_match("/'([^']+)'/", $eqright, $secondMatches)) {
			// 抽出できたらそれを返す
			return $secondMatches[1];
		}
		else {
			// 引用符がなければそのまま返す
			return $eqright;
		}
	}

	// 得られなければfalse
	return false;
}

// -------------------------------------------------------
// てがろぐCGIソースに直接書かれた設定値をまとめて読み込む		引数:てがろぐ本体のファイル名(省略時:tegalog.cgi)、返値:読み込めた数、OPENできなかったら-1、ファイルが存在しなかったら-2)
// -------------------------------------------------------
$tegalogSettingValues = [];
$tegalogSettingLines = [];
$tegalogShebangLine = '';

function extractTegalogSetVals($filename = 'tegalog.cgi')
{
	global $tegalogSettingValues;
	global $tegalogSettingLines;
	global $tegalogShebangLine;
	global $setVals;	// 探す設定値群

	$extractCount = 0;

	if(!file_exists($filename)) {
		// 指定ファイルがない場合
		errorMsg('指定のファイル「' . htmlsafe($filename) . '」は見つかりませんでした。');
		return -2;
	}

	// 探す設定値群の総数を得ておく（無駄なループを避けるため）
	$totalSetVals = count($setVals);

	// ローカルのてがろぐ本体を読み込みモードで開く
	$targetFile = fopen($filename, 'r');

	if($targetFile) {
		// ファイルが開けたら、中身を1行ずつ走査
		$linecount = 0;
		while(($line = fgets($targetFile)) !== false) {

			// シバン行なら保存する（まだ抽出できていない場合だけ）
			if( ! $tegalogShebangLine ) {
				$pattern = '/^#!.+/';
				if( preg_match($pattern, $line) ) {
					// 該当したら、行をまるごとそのまま保存（※改行も取り除かない）
					$tegalogShebangLine = $line;
					taskLog('既存のてがろぐCGIソースのシバン行は、<i>' . trim($tegalogShebangLine) . '</i> になっていることを確認しました。');
					continue;
				}
			}

			// 得たい設定値群すべてを探す
			foreach($setVals as $vname) {

				// 探す設定名のソースコード記述形式を作る（空白量に自由度を設けるため、正規表現を使う）
				$pattern = '/^\s*my\s*\$' . preg_quote($vname, '/') . '\s*=/';

				// 行の中から指定した変数定義を探す
				if( preg_match($pattern, $line) ) {
					// 見つかったら、行をまるごとそのまま保存（※改行も取り除かない）
					$tegalogSettingLines[$vname] = $line;
					// 値を抽出した結果も別途保存
					$tegalogSettingValues[$vname] = getInitialValue($line);
					// 抽出総数をカウント
					$extractCount++;

// debug //			echo "($extractCount) $vname <br>";
// debug //			echo "LINE:<code>〔" . $line . "〕</code><br>";
// debug //			echo "保存:<code>〔$tegalogSettingLines[$vname]〕</code><br>";
// debug //			echo "抽出:<code>〔$tegalogSettingValues[$vname]〕</code><br><br>\n";

					break;
				}

			} /* foreach */

			// 抽出数が設定値群数に達したらファイル内の走査ループを終わる (※同一の変数定義が2以上は存在しないことが前提)
			if( $extractCount >= $totalSetVals ) {
				taskLog('既存のてがろぐCGIソース内から、計 ' . $extractCount . ' 個の設定値を抽出しました。');
				break;
			}

			// 300行を超えたら読まない (無駄なループを避けるため)
			$linecount++;
			if( $linecount > 300 ) {
				taskLog('既存のてがろぐCGIソース内から、' . $totalSetVals . ' 個の設定値を抽出する必要がありますが、' . $extractCount . ' 個しか抽出できませんでした。');
				break;
			}

		} /* while */

		fclose($targetFile); // ファイルを閉じる
	}
	else {
		// ファイルを開けなかったら
		errorMsg("ローカルのてがろぐ本体ファイルを開けませんでした。");
		return -1;
	}

	return $extractCount;
}

// ---------------------------------------------------------------------------
// てがろぐINIファイルに書かれた設定を読んで望みのKEYに対するVALUEを調べて返す		引数1:欲しいKEY名、引数2:設定ファイル名(省略時=tegalog.ini)、返値:そのVALUE／(KEYが見つからなければfalse、OPENできなくてもfalse、ファイルが存在しなくてもfalse)
// ---------------------------------------------------------------------------
function getKeyValueInTegalogIni( $reqkey, $filename = 'tegalog.ini')
{
	static $tegalogIni = null;	// 同じファイルを何度も読まずに済むように、読んだデータはずっと保持する。(static)

	// まだINIデータを読んでいない場合にだけ、指定INIファイルから読み込む
	if( $tegalogIni === null ) {

		// 一応、ファイルの存在を先に確認する
		if(!file_exists($filename)) {
			// 指定ファイルがない場合
			errorMsg("指定のファイル「" . htmlsafe($filename) . "」は見つかりませんでした。");
			return false;
		}

		// ファイルがあれば読んで、INIの中身を連想配列に格納する (※てがろぐINIは、PHPの parse_ini_file ではSyntax Errorになるので自前で処理する必要がある！)
		$loadedData = fopen($filename, 'r');
		if($loadedData) {
			// ファイルが開けたら、中を走査
			while(($line = fgets($loadedData)) !== false) {

				// 文字列を = で分割
				list($ikey, $ivalue) = explode('=', $line, 2);
				$ikey = trim($ikey);

				// キーがある場合だけ連想配列に格納
				if( $ikey ) {
					$tegalogIni[$ikey] = trim($ivalue);
				}
			}
			fclose($loadedData); // ファイルを閉じる
			taskLog('てがろぐの設定ファイルを読み込みました。');
		}
		else {
			// ファイルを開けなかったら
			errorMsg("ローカルのてがろぐINIファイルを開けませんでした。");
			return false;
		}

	}

	// 指定されたキーが連想配列に存在するか確認し、存在する場合は値を返す。
	if( isset($tegalogIni[$reqkey]) ) {
		return $tegalogIni[$reqkey];
	}
	else {
		// キーが存在しなければfalse
		return false;
	}
}

// --------------------------------------
// ローカルのてがろぐバージョン番号を得る		引数:てがろぐ本体のファイル名(省略時:tegalog.cgi)、返値:バージョン番号文字列(該当がなければ空文字列、OPENできなかったら-1、ファイルが存在しなかったら-2)
// --------------------------------------
function getLocalTegalogVer($filename = 'tegalog.cgi')
{
	$version = '';

	if(!file_exists($filename)) {
		// 指定ファイルがない場合
		errorMsg("指定のファイル「" . htmlsafe($filename) . "」は見つかりませんでした。");
		return -2;
	}

	// ローカルのてがろぐ本体を読み込みモードで開く
	$targetFile = fopen($filename, 'r');

	if($targetFile) {
		// ファイルが開けたら、中を走査
		while(($line = fgets($targetFile)) !== false) {
			// 行にバージョン番号文字列を含むかを確認
			if(strpos($line, 'my $versionnum =') !== false) {
				// あれば引用符で囲まれた文字列を抽出
				if(preg_match("/'([^']+)'/", $line, $matches)) {
					$version = $matches[1];
					break; // 最初に見つかった時点で終了
				}
			}
		}
		fclose($targetFile); // ファイルを閉じる
	}
	else {
		// ファイルを開けなかったら
		errorMsg("ローカルのてがろぐ本体ファイルを開けませんでした。");
		return -1;
	}

	return $version;
}

// ----------------------------------------
// バージョン番号文字列を比較用の数値にする		引数:バージョン番号文字列(例：1.2.3)
// ----------------------------------------
function convVerStrToNum( $verStr )
{
	list($majorver, $minorver, $subver) = explode('.', $verStr);
	$ret = ( $majorver * 10000 ) + ( $minorver * 100 ) + $subver;
	return $ret;
}

// ----------------------------------------
// 新しいバージョンがあるかどうかを比較する		引数1:最新バージョン番号、引数2:ローカルバージョン番号、返値:1=より新しいVerがある、0=最新版を使用中、-1=最新版より新しいβ版を使用中
// ----------------------------------------
function compareVersions( $latestver, $localver )
{
	$latestnum = convVerStrToNum( $latestver );	// 最新版
	$localnum  = convVerStrToNum( $localver );	// ローカル

	if( $latestnum > $localnum ) {
		// 最新版の方が大きければ
		return 1;
	}
	elseif( $latestnum == $localnum ) {
		// 同じなら
		return 0;
	}
	else {
		// ローカルの方が大きければ
		return -1;
	}
}

// ----------------------
// 文字列を表示用に安全化		引数:対象文字列、返値:安全化後の文字列
// ----------------------
function htmlsafe( $str )
{
	return htmlspecialchars($str, ENT_QUOTES, 'UTF-8');
}

$AppWORKTITLE = 'てがろぐ本体お手軽アップデータ ';
$AppSEP = '';
$AppVERSION = '1.0.0';
$AppSTATUS = '';
$AppBODY = '';
$AppFOOTER = '<a href="' . htmlsafe($tegalogFileName) . '">てがろぐに戻る</a> / <a href="' . htmlsafe($tegalogFileName) . '?mode=admin">てがろぐ管理画面に戻る</a>';
$AppTHEME = '';

// --------------------------------
// バージョン情報の表示用HTMLを作る		引数1:最新バージョン、引数2:ローカルバージョン番号、引数3:比較値、返値:表示用HTML
// --------------------------------
function showVersions( $latestver, $localver, $compare )
{
	$msg = '<div class="versions">' .
		'<p class="localver">●このディレクトリで稼働中のバージョン： <i>Ver. <span class="ver">' . htmlsafe( $localver ) . '</span></i></p>' .
		'<p class="latestver">●公開されている正式版の最新バージョン： <i>Ver. <span class="ver">' . htmlsafe( $latestver ) . '</span></i></p>' .
		'<p class="vercheckresult">';
	if( $compare > 0 ) {
		$msg .= '<span class="mainRes hasNewVer">➡ 新しいバージョンが公開されています。</span><span class="addGuide">下記のボタンを押すと、バージョンアップできます。</span>';
	}
	elseif( $compare == 0 ) {
		$msg .= '<span class="mainRes useLatest">➡ 最新版をお使いです。</span>';
	}
	else {
		$msg .= '<span class="mainRes useBeta">➡ 最新版よりも新しいバージョン（β版）をご使用中のようです。</span>';
	}
	if( $compare <= 0 ) {
		$msg .= '<span class="subGuide">（バージョンアップの必要はありません。ただし、より<a href="https://www.nishishi.com/cgi/tegalog/nextversion/posts">新しいβ版</a>が公開されている可能性はあります。今のところβ版へのバージョンアップはサポートしていません。将来的にはします。たぶん。）</span>';
	}
	$msg .= '</p></div>';
	return $msg;
}

// --------------------------------
// バージョンアップ実行ボタンを作る
// --------------------------------
function showVerUpBtn()
{
	return '<ul class="systemmenu"><li><a href="?work=verup" title="てがろぐ本体を最新版にバージョンアップさせます。"><span class="jp">最新版にバージョンアップする</span><span class="en">Upgrade to the latest version</span></a></li></ul>';
}

// --------------------------------------
// てがろぐ設置ディレクトリかどうかの判定
// --------------------------------------
function isTegalogDir()
{
	return file_exists('fumycts.pl');
}

// ----------------------------------
// てがろぐが使っているCookie名を得る		引数:なし、返値:Cookie名(得られなくてもベース名は返す)
// ----------------------------------
function getCookieName()
{
	$cookieName = 'fomlid';
	$coexistflag = getKeyValueInTegalogIni('coexistflag');

	if( $coexistflag == 1 ) {
		// 固有識別文字列を使っているならそれを得る
		$coexistsuffix = getKeyValueInTegalogIni('coexistsuffix');
		if( $coexistsuffix !== false ) {
			// 得られたら加える
			$cookieName .= $coexistsuffix;
		}
		else {
			// 得られなかったらアラートを残す
			errorMsg("てがろぐ側の固有識別文字列の取得に失敗しました。");
		}
	}
	else {
		errorMsg("てがろぐで使っているCookieを取得できませんでした。");
	}

	return $cookieName;
}

// ----------------------------------------------------
// てがろぐCookieから(＝ログイン中の)セッションIDを得る			引数:Cookie名、返値:その値(なければfalse)
// ----------------------------------------------------
function getSessionIdFromCookie($cookieName)
{
	if( isset($_COOKIE[$cookieName]) ){
		return $_COOKIE[$cookieName];
	}
	return false;
}

// ----------------------------------------
// てがろぐにログインしているユーザIDを得る			引数:セッションID、セッション維持ファイル名(デフォルトは psif.cgi )、返値:ユーザID(なければ空文字、ファイルが読めなければfalse)
// ----------------------------------------
function getLoggedinUserId($sessionId, $filename = 'psif.cgi')
{
	$userId = '';

	if( ! $sessionId ) {
		// セッションIDの指定がない場合
		return false;
	}

	// ファイルの存在を確認する
	if(!file_exists($filename)) {
		// 指定ファイルがない場合
		errorMsg("指定のファイル「" . htmlsafe($filename) . "」は見つかりませんでした。");
		return false;
	}

	// セッション維持ファイルを読み込みモードで開く
	$sessionFile = fopen($filename, 'r');

	if($sessionFile) {
		// ファイルが開けたら、中を走査
		while(($line = fgets($sessionFile)) !== false) {
			// 指定のセッションIDを含む行を探す
			if(strpos($line, $sessionId) !== false) {
				// あれば、ユーザIDを抜き出す
				$elements = explode(',', $line);	// 対象行をカンマで分割
				if(count($elements) >= 3) {
					// 3番目の要素(Index:2)がユーザIDなのでそれを取得
					$userId = trim( $elements[2] );		// 最終行には改行コードが含まれるので消しておく
					break;
				}
			}
		}
		fclose($sessionFile); // ファイルを閉じる
	}
	else {
		// ファイルを開けなかったら
		errorMsg("ローカルのてがろぐセッション維持ファイルを開けませんでした。");
		return false;
	}

	return $userId;
}

// ------------------------------------
// 指定ユーザの権限レベルと名前を調べる		引数:ユーザID、返値:権限レベルの数値と名前の配列(ユーザが居なければfalse)
// ------------------------------------
function getUserLevelAndName($userId)
{
	// ユーザ一覧情報を得る
	$usersData = getKeyValueInTegalogIni('userids');
	if( $usersData === false ) {
		// 得られなかったら
		errorMsg("ユーザ一覧情報が得られませんでした。");
		return false;
	}

	// ユーザ情報の一覧を、ユーザごとに配列に分解する
	$usersList = explode('<,>', $usersData);

	// 指定ユーザの情報を探す
	foreach( $usersList as $oneUser ) {

		// そのユーザの情報を要素ごとに分解する
		$userInfo = explode('<>', $oneUser);

		// ユーザを探す(＝ユーザIDと先頭要素の一致を確認する)
		if( $userId == $userInfo[0] ) {
			// 一致したら第2要素(Index:1)と第3要素(Index:2)を返す（それが権限レベルの値と名前なので）
			return [ $userInfo[1], $userInfo[2] ];
		}

	}

	// 見つからなかったらfalse
	return false;
}

// --------------------------------------------
// てがろぐにログインしているかどうかを確認する		引数:なし、返値:ログインしているユーザID／ログインしていなければfalse
// --------------------------------------------
function checkLoggedin()
{
	global $tegalogSettingValues;

	$userId = getLoggedinUserId( getSessionIdFromCookie( getCookieName() ), $tegalogSettingValues['passfile']);
	if( !$userId ) { return false; }	// ログインしていない場合も、セッションIDファイルが読めなかった場合も、falseを返す。
	return $userId;
}


// ========================================================
// ▼メイン処理（準備編：どの場合でも最初に実行する処理群）
// ========================================================
date_default_timezone_set('Asia/Tokyo');
$readyToNextStep = true;

// ログをファイルに出力する場合の準備
$workinglogFileName = 'tegup.log';
if( $outputLogToFile == 1 ) {
	// ログをファイルにも出力する場合は中身をクリアしておく
	$content = '▼作業ログ ' . date("Y-m-d H:i:s") . " 開始\n";
	file_put_contents($workinglogFileName, $content);
}

// ユーザ設定値の確認
$tegalogFileName = trim($tegalogFileName);
if( !is_numeric($requiredUserLv) ) { errorEnd('<p>PHPソース冒頭の $requiredUserLv には、0～9 の範囲の整数のみを指定して下さい。</p>'); }
elseif( $requiredUserLv < 0 ) { $requiredUserLv = 0; }

// ―――――――
// 設置場所の確認
if( isTegalogDir() === false ) {
	errorEnd('<p>このディレクトリには、てがろぐCGIは設置されていないようです。</p><ul><li>このPHPは、<u>てがろぐCGIを設置しているディレクトリ</u>に置いてご使用下さい。（サブディレクトリや親ディレクトリではなく、同じディレクトリに置く必要があります。）</li><li>このPHPは、<u>既に稼働している『てがろぐ』</u>のバージョンアップ専用です。新規のセットアップ用途には使えません。</li></ul>');
	exit;
}

// ――――――――――――――――――
// てがろぐ本体ファイルから設定値の抽出
$loadedSets = extractTegalogSetVals($tegalogFileName);
if( $loadedSets == -2 ) {
	// ファイルが存在しない場合
	if( $tegalogFileName == 'tegalog.cgi' ) {
		// 指定ファイル名が tegalog.cgi のままの場合
		errorEnd('<p>このディレクトリには、<strong>tegalog.cgi</strong> ファイルが見つかりませんでした。</p><p>もし、tegalog.cgi のファイル名を変更して使っているなら、そのファイル名をこのPHPのソースコード冒頭にある設定欄に記載してから、再度実行して下さい。</p>');
	}
	else {
		// 変更されている場合
		errorEnd('<p>このディレクトリには、' . htmlsafe($tegalogFileName) . ' ファイルが見つかりませんでした。</p><p>tegalog.cgi の変更ファイル名を間違いなく入力できているかどうか、設定を再確認して下さい。</p>');
	}
}
elseif( $loadedSets == -1 ) {
	// OPENできなかった場合
	errorEnd('<p>何らかの原因で、ファイル ' . htmlsafe($tegalogFileName) . ' を開けませんでした。ファイルの中身が読めないので、処理を続行できません。</p>');
}
elseif( $loadedSets < count($setVals) ) {
	// 設定値は読めたが設定値の総数(＝配列$setValsの要素数)に満たなかった場合は、アラートを残す
	errorEnd('<p>ファイル ' . htmlsafe($tegalogFileName) . ' の中からは、想定よりも少ない ' . $loadedSets . '個の設定値しか読み取れませんでした。</p><ul><li>このファイルが本当に「てがろぐ」の<u>本体ファイル</u>なのかどうかをご確認下さい。（デフォルトファイル名は tegalog.cgi です。）</li><li>もし間違いがない場合、いま稼働している「てがろぐ」は、このPHPツール「TegUp」では対応していないくらい未来のバージョンの「てがろぐ」かも知れません。</li><li>その場合は、当ツール「TegUp」のバージョンが古すぎるということですから、作者サイト等からまずこのPHP「TegUp」の最新版を手に入れて上書き設置してから再度お試し下さい。</li></ul><p>※本来は、<u>' . count($setVals) . '個の設定値</u>が読み取れるはずです。<br>※このPHPツール「TegaUp」側の誤動作だと思われる場合は、作者までお知らせ頂けるとありがたいです。</p>');
}
taskLog('てがろぐCGI本体が、' . htmlsafe($tegalogFileName) . ' のファイル名で存在していることを確認しました。');

// ―――――――――――――――――――――――――――――――――――――――
// てがろぐINIファイルの設定値を読む（ついでに、カラーテーマの設定を反映させる）
$conpanecolortheme = getKeyValueInTegalogIni('conpanecolortheme', $tegalogSettingValues['setfile']);
if( $conpanecolortheme == 1 ) { $AppTHEME = 'themeKHA'; }
elseif( $conpanecolortheme == 2 ) { $AppTHEME = 'themeFGR'; }
elseif( $conpanecolortheme == 3 ) { $AppTHEME = 'themeSKR'; }
elseif( $conpanecolortheme == 4 ) { $AppTHEME = 'themeBDU'; }
elseif( $conpanecolortheme == 5 ) { $AppTHEME = 'themeMKN'; }
elseif( $conpanecolortheme == 6 ) { $AppTHEME = 'themeKRM'; }

// ―――――――――――――――――――――――――
// ログインユーザを確認する（確認しない設定なら省略）
if( $requiredUserLv > 0 ) {
	// ログインチェックする場合
	$loginUserId = checkLoggedin();
	if( $loginUserId !== false ) {
		// ログインしていれば、権限Lvと名前を調べる
		list( $uLevel, $uName ) = getUserLevelAndName( $loginUserId );
		// 権限が足りているかどうかを確認
		if( $uLevel >= $requiredUserLv ) {
			// 足りている場合
			$AppBODY .= '<p>' . htmlsafe($uName) . 'さん、こんにちは。<small>（現在、ユーザID「' . $loginUserId . '」でログイン中です。）</small></p>';
			taskLog('てがろぐ側で、ユーザID「' . $loginUserId . '」(' . htmlsafe($uName) . '／権限Lv.' . $uLevel . ')でログインされていることを確認しました。このユーザには、TegUpの使用権があります。');
		}
		else {
			// 足りていない場合
			$AppBODY .= '<p>' . htmlsafe($uName) . 'さん、あなたのIDに付与されている権限は Lv.' . $uLevel . ' なので、このツールを使うことはできません。</p><p>てがろぐ側で、Lv.' . $requiredUserLv . ' 以上の権限を持つユーザでログインし直して下さい。</p>';
			taskLog('てがろぐ側で、ユーザID「' . $loginUserId . '」(' . htmlsafe($uName) . '／権限Lv.' . $uLevel . ')でログインされていることを確認しましたが、当ツールを使うには権限が足りません。');
			$readyToNextStep = false;
		}
	}
	else {
		// ログインしていなければ
		$AppBODY .= '<p>このツールは、てがろぐ側でログインしていない状態では使えません。</p><p>てがろぐ側で、Lv.' . $requiredUserLv . ' 以上の権限を持つユーザでログインしてから、再度アクセスして下さい。<br>（もしくは、当ツール「TegUp」を、ログインしていなくても使用可能な設定に変更して下さい。）</p>';
		taskLog('てがろぐ側でのログイン状態を確認できませんでした。');
		$readyToNextStep = false;
	}
}

// ――――――――――――――
// バージョンを取得して比較する
$tegLatestVer = getTegalogLatestVer('official');		// てがろぐ(正式版)の最新バージョン番号を得る
$tegLocalVer = getLocalTegalogVer( $tegalogFileName );	// 同一ディレクトリに設置されているてがろぐのバージョン番号を得る
taskLog('設置されているてがろぐは Ver ' . $tegLocalVer . ' で、最新の正式版は Ver ' . $tegLatestVer . ' だと分かりました。');

// バージョンを比較する
$hasNewVer = compareVersions( $tegLatestVer, $tegLocalVer );


// ========================
// ▼メイン処理（本作業編）
// ========================
if( $readyToNextStep ) {

	if( !isset($_GET["work"]) ) {
		// --------------------------------------------------------------------
		// パラメータが設定されていなければ、バージョンを案内する初期画面を表示
		// --------------------------------------------------------------------
		$AppBODY .= '<p class="firstGuide">今お使いのてがろぐのバージョンよりも新しいバージョンが公開されている場合は、ワンクリックで最新版にバージョンアップします。</p>';
		$AppBODY .= showVersions( $tegLatestVer, $tegLocalVer, $hasNewVer );
		if( $hasNewVer > 0 ) {
			// バージョンアップボタンを表示
			$AppBODY .= showVerUpBtn();
		}

		// 作業ログを埋め込み(非表示)
		$AppBODY .= "\n" . '<div style="display:none;" id="TaskLogBox" class="logCover taskCover"><h2>作業ログ：</h2>' . taskLog() . '</div>';
	}
	elseif( $_GET["work"] == 'verup' ) {
		// ------------------------------------------------------------------------------
		// バージョンアップ作業が指定されていれば、バージョンを再確認してから作業を進める
		// ------------------------------------------------------------------------------
		if( $requiredUserLv > 0 ) {
			$AppSTATUS = 'ユーザ「' . htmlsafe($uName) . '」( ' . $loginUserId . ' )でログイン中';
		}
		$AppBODY = '';

		// 動作要件の確認
		if(!class_exists('ZipArchive')) {
			// ZipArchive クラスが使えない場合
			errorEnd('<p>お使いのサーバでは、PHPからZIPの圧縮や展開をするための ZipArchive クラスが使えないようです。したがって、ZIPの圧縮・展開操作ができないため、バージョンアップ処理を開始できません。</p><p>このメッセージが見えた場合、まだダウンロードも含めて一切何の処理も実行していません。特に後始末等の必要はありませんので、手動でバージョンアップして下さい。（※サーバ管理者に対して ZipArchive クラスを使用可能にするよう要求できるならそうして頂くと、TegUpでバージョンアップできるようになります。）</p>');
		}

		if( $hasNewVer > 0 ) {
			// 新バージョンがあるなら進める
			$AppBODY .= upgradeTegalog();
		}
		elseif( $hasNewVer == 0 ) {
			// 既に最新版が稼働している場合
			$AppBODY .= '<p>既に最新版にバージョンアップされているため、作業は続行しませんでした。</p><p>（※バージョンアップボタンを手動で押したにもかかわらずこの画面が表示された場合は、ボタンを2回連続で押してしまったなど、複数の処理が並行して走ってしまった可能性があります。てがろぐの動作をご確認頂き、何か問題が発生している場合は、バックアップZIPからシステムを書き戻し、再度バージョンアップをやり直してみて下さい。てがろぐ側の動作に問題がなく、正常にバージョンアップが完了できているなら何も問題はありません。）</p>';
		}
		else {
			// 既にβ版が稼働している場合
			$AppBODY .= '<p>正式版の最新版よりも新しいバージョンが稼働しているため、作業は続行しませんでした。</p>';
		}

		// 作業ログを表示
		$AppBODY .= '<div id="TaskLogBox" class="logCover taskCover"><h2>作業ログ：</h2>' . taskLog() . '</div>';
	}
	else {
		// ----------------------------------
		// 上記以外：パラメータの値がおかしい
		// ----------------------------------
		errorEnd('<p>想定外のパラメータが指定されています。</p>');
	}
}

// ============================
// ▼メイン処理（共通後処理編）
// ============================

// $AppBODY .= 'coexistsuffix:' . getKeyValueInTegalogIni('coexistsuffix') . '<br>';
// $AppBODY .= 'coexistflag:' . getKeyValueInTegalogIni('coexistflag') . '<br>';
// $AppBODY .= 'CookieName:' . getCookieName() . '<br>';
// $AppBODY .= 'SessionId:' . getSessionIdFromCookie( getCookieName() ) . '<br>';
// $AppBODY .= 'UserId:' . getLoggedinUserId( getSessionIdFromCookie( getCookieName() ), $tegalogSettingValues['passfile']) . '<br>';
// $AppBODY .= 'UsersPrimitiveData:' . getKeyValueInTegalogIni('userids') . '<br>';
// $AppBODY .= 'UserLevel:' . $uLevel . '<br>';
// $AppBODY .= 'UserName:' . $uName . '<br>';

// アラートがあれば出力
$alerts = errorMsg();
if( $alerts ) {
	$AppBODY .= "\n" . '<div id="ErrorMsgBox" class="logCover errorCover"><h2>アラート：</h2>' . errorMsg() . '</div>' . "\n";
}



// ------------------------------------
// パーミッション値を表示用文字列に変換
// ------------------------------------
function showPermissionValue($pnum)
{
	return substr(decoct( $pnum ), -4);
}

// -------------------------------------
// 古いバックアップZIPファイルを一括削除		引数:何日以上前のファイルを削除するか、返値:削除したファイル数（ファイル一覧の取得ができなかったらfalse）
// -------------------------------------
function delOldBackupZIPs($intervalDays = 2)
{
	// 今日の日付を得ておく (※todayだと時刻情報がゼロになって正確に計算できないのでnowを使う)
	$today = new DateTime('now');

	// ディレクトリ内のファイル一覧を取得
	$files = scandir('./');
	if( $files === false ) {
		// 取得できなかったら、falseを返して終わる。
		errorMsg('ディレクトリ内のファイル一覧を取得できませんでした。');
		return false;
	}

	// 削除ファイル数のカウント用
	$delFileCounter = 0;

	// ディレクトリ内のファイルを1つずつ調べる
	foreach( $files as $onefile ) {

		// TegUpが生成したバックアップZIPファイルかどうかを確認した上で、ファイル名から日付部分を正規表現で抽出
		if( preg_match('/^BackupTegalog\d+\((\d+)\).+\.zip$/', $onefile, $matches) ) {

			// 比較用に日時データ化
			$backupDate = DateTime::createFromFormat('Ymd', $matches[1]);

			// 日付を比較して指定日数以上経過しているかを確認
			$interval = $backupDate->diff($today);
			if( $interval->days >= $intervalDays ) {
				// 経過していたらそのファイルを消す
				if( unlink($onefile) ) {
					$delFileCounter++;
					taskLog('過去のバックアップファイル <i>' . $onefile . '</i> を削除しました。');
				}
				else {
					// 消せなかったら (※エラーにはしない)
					taskLog('過去のバックアップファイル <i>' . $onefile . '</i> を削除しようとしましたが、削除できませんでした。');
				}
			}
		}

	}

	return $delFileCounter;
}

// -----------------------------------------
// 既存のてがろぐファイルをZIPにバックアップ		引数1:バックアップ対象の選択番号、引数2:バックアップ対象のバージョン番号、返値:成功=生成したZIPファイル名、失敗=false
// -----------------------------------------
function backupPresentTegalog($targetType, $presentVer)
{
	global $tegalogSettingValues;
	global $tegalogFileName;

	// バックアップ(圧縮)対象ファイルを決める
	if( $targetType == 0 ) {
		// 何もバックアップしない
		taskLog('何もバックアップしない設定なので、バックアップ処理はスキップしました。');
		return true;
	}

	$files = [
		$tegalogFileName,	/* てがろぐ本体ファイル1 */
		'fumycts.pl'		/* てがろぐ本体ファイル2 */
	];
	if( $targetType == 2 ) {
		// 追加
		array_push($files, 
			$tegalogSettingValues['passfile'],	/* パスワード・セッションID保存ファイル */
			$tegalogSettingValues['setfile'],	/* 設定ファイル */
			$tegalogSettingValues['bmsdata']	/* データファイル */
		);
	}

	// 圧縮後のZIPファイル名を作る
	$presentVer = str_replace('.', '', $presentVer);	// バージョン番号文字列からドット記号を削除する
	$nowdate = date("Ymd");								// 現在日
	$randchars = genRandStr(8);							// 推測されにくくするランダム英数字
	$zipFileName = 'BackupTegalog' . $presentVer . '(' . $nowdate . ')' . $randchars . '.zip';

	// 対象ファイル群を圧縮
	$res = archiveZip($files, $zipFileName);
	if( $res < 0 ) {
		// ZIPの生成に失敗
		return false;
	}
	else {
		// ZIPの生成に成功
		taskLog('合計 ' . $res . '個のファイルを、ZIPファイル <a href="' . $zipFileName . '" download>' . $zipFileName . '</a> にバックアップしました。');

		if( $res < count($files) ) {
			// ZIPの生成はできたがファイル数が足りない
			taskLog('※いくつかのファイルは圧縮できませんでした。エラーメッセージを確認して下さい。');
		}
	}

	// 生成できたZIPファイル名を返す
	return $zipFileName;
}

// -----------------------------------------------------
// 最新版のてがろぐZIP（最小構成）をダウンロードしてくる		引数:保存したいZIPファイル名、返値:ファイルサイズ(Bytes)、-1=アクセス失敗、-2=ダウンロード失敗or保存失敗
// -----------------------------------------------------
function downloadTegalogZip($saveFileName)
{
	$fileUrl = 'https://www.nishishi.com/cgi/tegalog/tegalog.zip';

	// HTTPステータスコードを確認
	if( checkExistUrl($fileUrl) < 1 ) {
		// 200 OK 以外の場合
		return -1;
	}

	// ファイルをダウンロード
	if( file_put_contents($saveFileName, file_get_contents($fileUrl)) === false) {
		// 失敗した場合
		return -2;
	}

	// いま保存したファイルのサイズを調べる
	$zipFileSize = filesize($saveFileName);
	$showSize = number_format(($zipFileSize / 1024), 1);
	taskLog('最新版のてがろぐZIPファイル ' . $showSize . 'KBをダウンロードして、一時的に <i>' . $saveFileName . '</i> に保存しました。（作業後に自動削除されます。）');

	return $zipFileSize;
}

// ---------------------------------------
// てがろぐZIPを一時ディレクトリに展開する		引数1:ZIPファイル名、引数2:展開先ディレクトリパス、返値:展開ファイル数、-1=ZIPの展開に失敗、-2=一時DIRの作成に失敗
// ---------------------------------------
function unzipNewTegalog($zipFileName, $extractDir = './temp/')
{
	global $tempDirPermission;

	// ディレクトリが存在しない場合は作成
	if( !file_exists($extractDir) ) {
		$dirres = mkdir($extractDir, $tempDirPermission, true);	// 第3引数をtrueにするとディレクトリを再帰的に作成
		if( $dirres === false ) {
			// ディレクトリの作成に失敗
			return -2;
		}
	}
	taskLog('てがろぐZIPファイルの展開先として、一時的にサブディレクトリ <i>' . $extractDir . '</i> をパーミッション <i>' . sprintf('%04o', $tempDirPermission) . '</i> で作成しました。（作業後に自動削除されます。）');

	// ZIPファイルを展開
	$zipres = extractZip($zipFileName, $extractDir);
	if( $zipres == -1 ) {
		// ZIPファイルの展開に失敗
		return -1;
	}

	// 展開できたファイル数を得る
	$fileCount = count(scandir($extractDir)) - 2;	// DIRリストから . と .. を除いて数える
	taskLog('てがろぐZIPファイルから ' . $fileCount . ' 個のファイルを展開しました。（作業後に自動削除されます。）');
	return $fileCount;
}

// ----------------------------------------
// 指定ファイル群のパーミッション値を調べる		引数:調べるファイル名の配列、返値:ファイル名に対するパーミッション値を格納した連想配列、1つでも見つからなければfalse
// ----------------------------------------
function checkPermissions($targets)
{
	$res = [];

	foreach( $targets as $one ) {
		if( file_exists($one) ) {
			// ファイルが存在していればパーミッション値を調べて連想配列に格納
			$res[$one] = fileperms($one);
			taskLog('ファイル ' . $one . ' の現在のパーミッション値は、<i>' . showPermissionValue( $res[$one] ) . '</i> です。');
		}
		else {
			// ファイルがなければ
			return false;
		}
	}

	return $res;
}

// ------------------------------------------
// 指定ファイル群のパーミッション値を設定する		引数1:対象ファイル名の配列、引数2:設定パーミッション値の配列、返値:設定したファイル総数
// ------------------------------------------
function setPermissions($targets, $permissions)
{
	$changesCount = 0;

	foreach( $targets as $one ) {
		if( file_exists($one) ) {
			// ファイルが存在していれば、そのファイルに対応するパーミッション値が指定されているかどうかを確認
			if( isset($permissions[$one]) ) {
				// 指定されていればその値に変更する
				if( chmod($one, $permissions[$one]) ) {
					// 変更できたら
					$changesCount++;
					taskLog('ファイル ' . $one . ' のパーミッション値を、<b>' . showPermissionValue( $permissions[$one] ) . '</b> に変更しました。');
				}
				else {
					// 変更できなかったら
					errorMsg('ファイル ' . $one . ' のパーミッション値を、' . showPermissionValue( $permissions[$one] ) . ' に変更できませんでした。');
				}
			}
			else {
				// 指定されていなければ
				errorMsg('ファイル ' . $one . ' に対するパーミッション値が指定されていないため、変更しませんでした。');
			}
		}
		else {
			// ファイルがなければ
			errorMsg('パーミッション値の変更対象として指定されたファイル ' . $one . ' が見つかりませんでした。');
		}
	}

	return $changesCount;
}

// ----------------------------
// PATHにファイル名を加えて返す		引数1:ベースPATH、引数2:ファイル名、返値:PATH文字列
// ----------------------------
function makeFilePath($basePath, $fileName)
{
	if(substr($basePath, -1) === '/') {
		// ベースPATHの最後がスラッシュの場合は、そのまま連結して返す。
		return $basePath . $fileName;
	}
	// そうでない場合は、間にスラッシュを加えて連結して返す。
	return $basePath . '/' . $fileName;
}

// -----------------------------------------------------------------
// 新バージョンのtegalog.cgiの各種設定値を、既存の設定値に書き換える		引数:新版ファイルが置かれているディレクトリ名、返値:情報を記録した配列 （※エラーがあればその場でエラーメッセージを吐いてプログラムを終わる。この処理は飛ばせないので。）
// -----------------------------------------------------------------
function rewriteSetValsOfNewTegalogCgi($newDir)
{
	global $tegalogSettingLines;
	global $tegalogShebangLine;
	global $setVals;	// 探す設定値群
	global $tegalogFileName;

	// 記録用(返値用)
	$ret = array(
		'lines'		=> 0,	/* 読んだ全行数 */
		'checks'	=> 0,	/* 設定反映対象として見つけた個数 */
		'rewrites'	=> 0	/* 書き換えた個数 */
	);

	// 探す設定値群の総数を得ておく（無駄なループを避けるため）
	$totalSetVals = count($setVals);

	// 新バージョンとして一時ディレクトリに格納されている(ハズの) tegalog.cgi のファイルパスを作る
	$tempTegalogFile = makeFilePath( $newDir , 'tegalog.cgi' );

	// あるかどうか確認する
	if(!file_exists($tempTegalogFile)) {
		// 指定ファイルがない場合
		errorEnd('<p>一時ディレクトリにあるハズのファイル「' . $tempTegalogFile . '」が見つかりませんでした。</p>');
		exit;
	}

	// 書き換え結果を新ファイルに書き出す用
	$newTegalogFile = makeFilePath( $newDir , $tegalogFileName );	// ファイルパス
	$rewroteFile = '';	// ファイル中身

	// 新版てがろぐ本体を読み込みモードで開く
	$targetFile = fopen($tempTegalogFile, 'r');

	if($targetFile) {
		// ファイルが開けたら、中身を1行ずつ走査
		while(($line = fgets($targetFile)) !== false) {

			// 読んだ行数の保持
			$ret['lines']++;

			// 1行目だったらシバン行を確認する
			if( $ret['lines'] == 1 ) {
				$pattern = '/^#!.+/';
				if( preg_match($pattern, $line) ) {
					// 該当したら、保存していたシバン行の方を出力に使う
					$rewroteFile .= $tegalogShebangLine;
				}
				else {
					// 該当しなかったら「1行目がシバン行ではない」のでおかしい
					errorEnd('<p>ファイルの1行目が「#!」で始まるシバン行ではないため、このファイルはおそらくてがろぐCGIの本体ファイルではありません。</p><p>以下の可能性があります。</p><ul><li>誤ったZIPがダウンロードされた。</li><li>てがろぐ側の仕様が新しくなっていて、当ツール「TegUp」の現行バージョンでは対処できない。（新しいバージョンを探して差し替えて下さい。）</li><li>何らかの事情でファイルが壊れていた。（再度ダウンロードから再試行して下さい。）</li></ul>');
					exit;
				}
				taskLog('書換：シバン行：<b>' . htmlsafe(trim($rewroteFile)) . '</b> に書き換えました。');
				continue;
			}

			// 書換対象数が設定値群数に満たない場合にだけ、書き換え対象を探す
			if( $ret['checks'] < $totalSetVals ) {

				// 設定値群すべてを探す
				$alreadyOutput = false;
				foreach($setVals as $vname) {

					// 探す設定名のソースコード記述形式を作る（空白量に自由度を設けるため、正規表現を使う）
					$pattern = '/^\s*my\s*\$' . preg_quote($vname, '/') . '\s*=/';

					// 行の中から指定した変数定義を探す
					if( preg_match($pattern, $line) ) {
						// 見つかったら
						$ret['checks']++;
						// 保存していた行があるかどうかを確認
						if( isset( $tegalogSettingLines[$vname] ) ) {
							// あればそれを出力に使う
							$rewroteFile .= $tegalogSettingLines[$vname];
							// 書き換え数を更新
							$ret['rewrites']++;
							// 書き換え済みフラグを立てる
							$alreadyOutput = true;
							taskLog('書換：設定値' . $ret['checks'] . '：<b>' . htmlsafe(trim($tegalogSettingLines[$vname])) . '</b> に書き換えました。');
						}
						else {
							taskLog('設定値 ' . trim($line) . ' に対する書き換えデータがなかったので、書き換えませんでした。');
						}
						// どちらにせよ見つかったならforeachループは抜ける
						break;
					}

				} /* foreach */

				if( $alreadyOutput ) {
					// 既に書き換えが行われていれば
					continue;
				}
			}

			// 何の処理対象にもなっていない場合は、その行をそのまま出力する
			$rewroteFile .= $line;

		} /* while */

		// ファイルを閉じる
		fclose($targetFile);

		// ログ
		taskLog('新Verファイル中の合計 ' . $ret['lines'] . ' 行を走査して、' . $ret['checks'] . ' 個の設定行を発見し、' . $ret['rewrites'] . ' 行を元の ' . htmlsafe($tegalogFileName) . ' と同じ内容に書き換えました。');

		// 書き換え結果を(実際に使うファイル名で)ファイルとして出力する
		$fpc = file_put_contents( $newTegalogFile, $rewroteFile );
		if( $fpc === false ) {
			// 出力できなかったら
			errorEnd('<p>設定値を反映させた書き換え結果を、ファイル ' . $newTegalogFile . ' に出力できませんでした。</p>');
			exit;
		}

		// ログ
		taskLog('書き換えた内容を <i>' . $newTegalogFile . '</i> に出力しました。（' . number_format(($fpc / 1024), 1) . 'KB）');
	}
	else {
		// ファイルを開けなかったら
		errorEnd('<p>一時ディレクトリにあるハズのファイル「' . $tempTegalogFile . '」を開けませんでした。</p>');
		exit;
	}

	return $ret;
}

// --------------------------------------------------------------------
// 仮ディレクトリに存在する指定ファイル群を本番ディレクトリにコピーする		引数1:Fromディレクトリ名、引数2:Toディレクトリ名、引数3:対象ファイル名の配列、返値:コピーできたファイル数
// --------------------------------------------------------------------
function copyFiles($fromDir, $toDir, $targets)
{
	$copyCount = 0;

	foreach( $targets as $one ) {

		// PATHを作る
		$fromFile = makeFilePath( $fromDir, $one );		// コピー元(From)ファイルのPATH
		$toFile   = makeFilePath( $toDir, $one );		// コピー先(To)ファイルのPATH

		if( file_exists($fromFile) ) {
			// ファイルが存在していればコピー
			if(copy($fromFile, $toFile)) {
				// 正常にコピーされたらカウント
				$copyCount++;
				taskLog('仮ファイル <i>' . $fromFile . '</i> を、本番ファイル <b>' . $toFile . '</b> に上書きコピーしました。');
			}
			else {
				// コピーに失敗したら
				errorMsg('仮ファイル <i>' . $fromFile . '</i> を、本番ファイル <b>' . $toFile . '</b> に上書きコピーできませんでした。');
			}
		}
		else {
			// ファイルがなければ
			errorMsg('コピー元として使うはずの仮ファイル <i>' . $fromFile . '</i> が見つかりませんでした。');
		}
	}

	return $copyCount;
}

// ------------------------------
// 指定ディレクトリを再帰的に削除		引数:削除するディレクトリ名、返値:true/false
// ------------------------------
function deleteDirectory($delTargetDir)
{
	// 安全装置
	if( strpos($delTargetDir, '/') === 0 || strpos($delTargetDir, '..') !== false ) {
		// スラッシュで始まっていたり、上位ディレクトリを参照していたりする場合は拒否する
		errorEnd('上位ディレクトリを削除することはできません。');
		exit;
	}

	if(!is_dir($delTargetDir)) {
		return false;
	}

	$files = array_diff(scandir($delTargetDir), array('.', '..'));

	foreach( $files as $onefile ) {
		$path = $delTargetDir . DIRECTORY_SEPARATOR . $onefile;
		if( is_dir($path) ) {
			deleteDirectory($path);		// 再帰呼び出し
		}
		else {
			unlink($path);
		}
	}

	return rmdir($delTargetDir);
}


// -----------------------------------------------
// ■てがろぐCGIをバージョンアップさせるメイン処理
// -----------------------------------------------
function upgradeTegalog()
{
	global $tegalogFileName;
	global $backupTargets;
	global $tegLocalVer;
	global $tegLatestVer;

	taskLog('バージョンアップ処理を始めます。（※これ以後に処理が中断した場合、仮作成されたファイルやディレクトリが削除されずに残る可能性があります。）');

	// 作業用の仮名称を作る
	$uniqueName = genRandStr(10);
	$extractDir = './temp_tegup_' . $uniqueName . '/';			// 展開先ディレクトリパス(一時使用)
	$downloadedFile = 'tegalog_zip_' . $uniqueName . '.zip';	// 保存ZIPファイル名(一時使用)

	// 上書き設置する対象ファイル群 (※注:作業過程で適宜ディレクトリ名を加えるので、ここではファイル名だけを列挙しておく)
	$upgradeTargetFileNames = array(
		$tegalogFileName ,
		'fumycts.pl'
	);

	// ――――――――――――――――――――
	// 古いバックアップZIPがあれば削除しておく
	$dobzCount = delOldBackupZIPs(2);
	if( $dobzCount > 0 ) {
		// 1つ以上のファイルを削除していれば
		taskLog('2日以上前に生成された古いバックアップZIPファイル、計 ' . $dobzCount . ' 個を一括削除しました。');
	}

	// ――――――――――――――――――――――――――――――
	// 稼働しているファイル群のパーミッション値を調べて保持しておく
	$reqPermissionVals = checkPermissions($upgradeTargetFileNames);
	if( $reqPermissionVals === false ) {
		// 得られなかったら
		errorEnd('パーミッション値の取得に失敗しました。');
		exit;
	}

	// (メモ) →以後、$reqPermissionVals[$tegalogFileName] や $reqPermissionVals['fumycts.pl'] でパーミッション値が得られる。

	// ――――――――――――――――――――
	// 現状のファイルをバックアップ圧縮しておく
	$backupZipFileName = backupPresentTegalog($backupTargets, $tegLocalVer);
	if( $backupZipFileName === false ) {
		// バックアップに失敗したなら
		errorEnd("<p>バックアップ用のZIPファイルを作成できませんでした。</p>");
		exit;
	}

	// ―――――――――――――――――――――
	// 最新の正式版ZIPファイルをダウンロードする
	$downloadSize = downloadTegalogZip($downloadedFile);
	if( $downloadSize == -1 ) {
		// アクセス失敗なら
		errorEnd('ダウンロードするファイルがあるはずのURLにアクセスできませんでした。');
		exit;
	}
	elseif( $downloadSize == -2 ) {
		// ダウンロード失敗か、保存失敗
		errorEnd('ダウンロードに失敗したか、または、ダウンロードしたファイルの保存に失敗しました。');
		exit;
	}

	// ――――――――――――――――――――――――
	// 最新の正式版ZIPファイルを一時ディレクトリに展開
	$extractFiles = unzipNewTegalog($downloadedFile, $extractDir);
	if( $extractFiles == -2 ) {
		// 一時DIRの作成に失敗
		errorEnd('ZIPファイルを展開するための一時ディレクトリの作成に失敗しました。');
		exit;
	}
	elseif( $extractFiles == -1 ) {
		// ZIPの展開に失敗
		errorEnd('てがろぐ最新版のZIPファイルの展開に失敗しました。');
		exit;
	}

	// ―――――――――――――――――――――――――――――――――
	// 新バージョンのtegalog.cgiの各種設定値を、既存の設定値に書き換える
	$rewroteRet = rewriteSetValsOfNewTegalogCgi( $extractDir );

	// ――――――――――――――――――――――――――――――――
	// tegalog.cgi(※実際に使うファイル名) と fumycts.pl を上書きコピー
	$copyCount = copyFiles($extractDir , './', $upgradeTargetFileNames);

	if( $copyCount < count($upgradeTargetFileNames) ) {
		// コピーできた数が、コピーすべき数よりも下回っている場合
		errorEnd('<p>新バージョンのファイルを、現在バージョンのファイルへ上書きコピーする処理に失敗しました。</p><p>本来、' . count($upgradeTargetFileNames) . ' ファイルを上書きコピーする必要があるところ、' . $copyCount . ' ファイルしかコピーできませんでした。動作権限や書き込み権限等を確認して下さい。</p>');
		exit;
	}

	// ―――――――――――――――――――――――
	// 各ファイルのパーミッション値を元通りに変更する
	$chpermCount = setPermissions($upgradeTargetFileNames, $reqPermissionVals);

	if( $chpermCount < count($upgradeTargetFileNames) ) {
		// コピーできた数が、コピーすべき数よりも下回っている場合
		errorEnd('<p>新しく上書きコピーしたファイルのパーミッション値の変更に失敗しました。</p><p>本来、' . count($upgradeTargetFileNames) . ' ファイルの値を設定する必要があるところ、' . $chpermCount . ' ファイルしか設定できませんでした。</p>');
		exit;
	}

	// ―――――――――――――
	// 作業サブディレクトリを削除
	if( deleteDirectory($extractDir) ) {
		// 削除できたら
		taskLog('作業用サブディレクトリ <i>' . $extractDir . '</i> を削除しました。');
	}
	else {
		// 削除できなかったら
		errorMsg('作業用サブディレクトリ ' . $extractDir . ' を削除できませんでした。手動で削除して下さい。');
	}

	// ――――――――――――――――――――
	// ダウンロードした作業用ZIPファイルを削除
	if( unlink($downloadedFile) ) {
		// 削除できたら
		taskLog('ダウンロードした作業用ZIPファイル <i>' . $downloadedFile . '</i> を削除しました。');
	}
	else {
		// 削除できなかったら
		errorMsg('ダウンロードした作業用ZIPファイル ' . $downloadedFile . ' を削除できませんでした。手動で削除して下さい。');
	}

	taskLog('すべての処理を終わりました。');

	// ―――――――――
	// 結果表示画面を作る
	$showRes = '
		<div class="resultBox">
			<h2>バージョンアップ作業を完了しました</h2>
			<p class="verUpRes">お使いのてがろぐCGIを、Ver ' . $tegLocalVer . ' から <strong class="newVerNum">Ver ' . $tegLatestVer . '</strong> へバージョンアップしました。</p>
			<p>お使いの<a href="' . htmlsafe($tegalogFileName) . '?mode=admin">てがろぐ管理画面</a>にアクセスして、正常にバージョンアップできていることをご確認下さい。</p>
			<p class="backupZip">※これまで稼働していたCGI本体ファイル群は、ZIPファイル <a href="' . $backupZipFileName . '" download">' . $backupZipFileName . '</a> に圧縮してバックアップしてあります。もし、動作がおかしい場合は、このZIPに含まれているファイルを書き戻すことで、前の状態を復元できます。</p>
		</div>
	';

	return $showRes;
}

?>
<!DOCTYPE html>
<html lang="ja">
<head>
	<meta charset="utf-8"><meta name="robots" content="noindex">
	<meta name="viewport" content="initial-scale=1">
	<title><?php echo $AppWORKTITLE; ?><?php echo $AppSEP; ?> TegUp <?php echo $AppVERSION; ?></title>
	<style>
		body { background-color:#aaccaa; font-family:"メイリオ",Meiryo,"Hiragino Kaku Gothic ProN","Hiragino Sans",sans-serif; }
		#contents { background-color:#ffffff; border:1px #008000 solid; }
		a:hover { color:red; }
		#header { background-color:#ccffcc; color:#000000; border-bottom:1px green solid; position:relative; }
		h1 { margin:0 0.3em; font-size:1.5em; padding:7px 0; line-height:1; }
		.adminhome a { display:block; width:3em; position:absolute; top:3px; right:3px; padding:3px 0; font-size:0.75em; font-weight:normal; line-height:1; text-decoration:none; background-color:#eee; border-radius:3px; border:1px solid #aaa; color:#005; text-align:center; }
		.workname { font-family:"Lucida Sans Unicode","Microsoft Sans Serif","Century Gothic",sans-serif; }
		.appname { font-size:0.8em; } .appname a { color:#050; text-decoration:none; display:inline-block; } .appname a:hover { text-decoration:underline; }
		#status { margin:0; padding:0.3em 0.5em; text-align:right; font-size:85%; color:#999; }
		#main { margin:0.1em 1em 1em 1em; }
		#footer { text-align:center; margin:1em; }
		.adminlinks a { display:inline-block; }
		#copyright { margin:0.3em 0.5em; padding:0.3em; font-size:75%; } #copyright a { text-decoration:none; color:#025; } #copyright a:hover { text-decoration:underline; }
		/* ▼汎用 */
		#sendinputs { font-size:120%; }
		.hidedetail { display:none; }
		.important { color:#cc0000; }
		.notice { font-size:0.8em; color:gray; display:inline-block; line-height:1.3; }
		.noticebox { margin:1em 0; padding:0.5em; border:1px solid #ccc; border-radius:1em; font-size:0.9em; background-color:#ffc; line-height:1.4; }
		/* ▼汎用ボタン */
		.btnlink { background-color:#eee; font-size:0.95em; line-height:1.2; display:inline-block; margin:0.5em 3px 0 0; padding:0.5em 0.67em; border-radius:3px; border:1px solid #aaa; text-decoration:none; color:#005; }
		.btnlink:hover, .adminhome a:hover { background-color:#e5f1fb; border-color:#0078d7; color:#0063ac; }
		.btnlink.pagenumhere { border-color: darkgreen; background-color:green; color:white; }
		/* ▼汎用テーブル */
		table.standard { border-collapse:collapse; border:1px solid green; }
		table.standard th, table.standard td { border:1px solid green; padding:0.2em 0.4em; }
		table.standard th { background-color:#dfd; }
		@media all and (max-width: 599px) {
			table.standard { font-size:0.8em; line-height:1.2; }
		}
		/* ▼一覧テーブル */
		.managetable { border:2px solid #808000; border-collapse:collapse; margin-bottom:0.5em; max-width:100%; }
		.managetable tr:hover td { background-color: #dfd; }
		.managetable th { border-width:1px; border-style:solid dotted; border-color:#808000; background-color:#ffffcc; padding:0.2em; font-size:0.9em; }
		.managetable td { border:1px dotted #808000; padding:0.1em 0.3em; background-color:#fff; }
		.mttitle { word-wrap:break-word; }
		.mtid { white-space:nowrap; }
		.mtcat { word-break: break-all; line-height:1.1; font-size:0.9em; }
		.smallbutton { font-size:0.8em; display:inline-block; text-decoration:none; border:1px solid gray; border-radius:0.5em; padding:0 0.25em; background-color:#eee; }
		.smallbutton:hover { background-color:blue; color:white !important; border-color:darkblue; }
		@media all and (max-width: 599px) {
			h1 { font-size:1rem; padding:0.25em 0; } .appname { font-size:1em; }
			.adminhome a { font-size:0.6em; padding:1px 0; top:1px; right:1px; }
			.managetable th { font-size: 0.67em; }
			.mtid { font-size: 0.8em; }
			.mttitle a { word-break: break-all; font-size: 0.9em; display:inline-block; line-height:1.1; }
			.mttime, .mtuser { font-size: 0.6em; }
			.mtcat { font-size: 0.55em; }
			.smallbutton { letter-spacing: -1px; font-size: 0.75em; padding: 0.5em 0.1em; }
		}
		@media all and (max-width: 359px) {
			.mttime, .mtuser { font-size: 0.55em; }
			.smallbutton { font-size: 0.67em; }
		}
		/* ▼入力枠 */
		fieldset { border:1px solid #ccc; border-radius:1em; display:inline-block; vertical-align:top; background-color:white; position:relative; }
		legend { margin:0 1.5em; padding:0 0.5em; border-radius:5px; font-weight:bold; background-color:#548d54; color:white; }
		.fieldsubset { margin:1em 0 0 0; padding-top:0.75em; border-top: 1px dashed gray; position:relative; } .fieldsubset .helpbox { top:1px; right:0; }
		.helpbox { position:absolute; top:-0.5em; right:0.25em; }
		.helpbox .help { display:inline-block; text-decoration:none; background-color:#fff; border:1px solid #ccc; border-radius:0.5em; padding:1px 0.25em; font-size:9px; max-width:6.75em; line-height:1.05; text-align:center; fill:#0000ff; }
		.helpbox .help svg { float:left; }
		.helpbox .help.uh { fill:green; max-width:5.75em; }
		.helpbox .help:hover { fill:red; background-color:#ffc; }
		@media all and (max-width: 500px) {
			.helpbox .help .label { display:none; }
		}
		/* ▼管理画面 */
		.systemmenu { list-style-type:none; margin:0; padding:0; }
		.systemmenu li { display:inline-block; }
		.systemmenu.withdetail li { display:flex; gap:1em; align-items:center; }
		.systemmenu.withdetail li .mdetail { font-size:0.9em; line-height:1.2; }
		.systemmenu.withdetail li a { flex-shrink: 0; }
		.systemmenu li a { display:block; background-color:blue; background-image:linear-gradient( 0deg, #000080, #0080ff ); color:white; border-radius:0.75em; padding:0.5em 1em; margin:0 1px 0.5em 0; text-decoration:none; min-width:5em; }
		.systemmenu li a.nop { background-color:gray !important; background-image:linear-gradient( 0deg, #888, #ccc ) !important; cursor:not-allowed; }
		.systemmenu li a span.jp { display:block; text-align:center; font-weight:bold; text-decoration:underline; }
		.systemmenu li a span.en { display:block; text-align:center; font-size:75%; }
		.systemmenucategory { margin:0.5em 0 0.3em 0; font-size:0.9em; color:#008080; }
		.systemmenucategory:first-child { margin-top:0; }
		.systemmenu a:hover { background-image:none; background-color:#ccddff; color:darkblue; }
		.systemmenu a.nop:hover { color:white; }
		.demoGuide { background-color:crimson; color:white; border-radius:1em; line-height:1.2; padding:0.5em; text-align:left; box-shadow:3px 3px 3px pink; }
		.demoGuide::before { content:'DEMO MODE：'; display:inline-block; font-weight:bold; background:white; color:crimson; margin:0 0.5em; padding:0.2em; font-size:0.9em; line-height:1; }
		.demoGuide u { text-decoration: underline double yellow; }
		@media all and (max-width: 450px) {
			.systemmenu.withdetail li { flex-direction:column; gap:0; }
		}
		/* ▼Themes */
		body.themeKHA { background-color:#c0b76a; } .themeKHA #header { background-color:khaki; } .themeKHA .systemmenu li a { background-image:linear-gradient( 0deg, #505000, #bbbb50 ); } .themeKHA .systemmenu a:hover { background-image:none; background-color:#f0e68c; color:#505000; }
		body.themeFGR { background-color:#95c664; } .themeFGR #header { background-color:#ccff99; } .themeFGR .systemmenu li a { background-image:linear-gradient( 0deg, #005000, #00c050 ); } .themeFGR .systemmenu a:hover { background-image:none; background-color:#cceeaa; color:darkgreen; }
		body.themeSKR { background-color:#f7cdd4; } .themeSKR #header { background-color:#ffeaed; } .themeSKR .systemmenu li a { background-image:linear-gradient( 0deg, #f04061, #f8aab9 ); } .themeSKR .systemmenu a:hover { background-image:none; background-color:#ffeaed; color:#cc1136; }
		body.themeBDU { background-color:#88a4cc; } .themeBDU #header { background-color:#d2ddec; } .themeBDU .systemmenu li a { background-image:linear-gradient( 0deg, #0e1a39, #877fac ); } .themeBDU .systemmenu a:hover { background-image:none; background-color:#ccccee; color:#0e1a39; }
		body.themeMKN { background-color:#eebd7c; } .themeMKN #header { background-color:#f7e1c0; } .themeMKN .systemmenu li a { background-image:linear-gradient( 0deg, #ef6b04, #febe78 ); } .themeMKN .systemmenu a:hover { background-image:none; background-color:#faddb1; color:#ef6b04; }
		body.themeKRM { background-color:#f0f0f0; } .themeKRM #header { background-color:#cccccc; } .themeKRM .systemmenu li a { background-image:linear-gradient( 0deg, #000000, #aaaaaa ); } .themeKRM .systemmenu a:hover { background-image:none; background-color:#000000; color:#ffffff; }
		/* TegUp */
		.versions p { margin:0.5em 0; padding:0.5em; }
		i { display:inline-block; font-style:normal; }
		.localver { color: green; background-color:#f0f9f0; }
		.latestver { color: blue; background-color:#f0f0ff; }
		.ver { font-size: 2em; }
		.vercheckresult .mainRes { font-size:1.25em; }
		.hasNewVer { color:crimson; font-weight:bold; }
		.useLatest { color:crimson; }
		.subGuide { font-size:0.8em; color:gray; }
		.newVerNum { color:crimson; }
		/* taskLog */
		.logCover { margin:1em 0; }
		.logCover h2 { margin:0; padding:0.5em 0.5em 0.25em; font-size:1.1em; line-height:1; font-weight:normal; border-radius:0.5em 0.5em 0 0; color:white; width:fit-content; }
		.taskCover h2 { background-color:gray; }
		.taskLog { font-size:0.9em; margin:0; padding:1em; border:1px solid gray; background-color:#f0f0f0; list-style-type:none; }
		.taskLog li { line-height:1.2; margin:0; padding:0.15em; }
		.taskLog li:nth-child(even) { background-color:#fcfcfc; }
		.taskLog time { display:inline-block; margin-right:0.5em; color:darkblue; }
		.taskLog time::before { content: '['; }
		.taskLog time::after { content: ']'; }
		.taskLog i { color:#078; }
		.taskLog b { font-weight:normal; color:#b00; }
		/* errorMsgs */
		.errorCover { margin:1em 0; }
		.errorCover h2 { background-color:tomato; }
		.errorMsgs { border:1px solid tomato; background-color:lavenderblush; margin:0; padding:1em 1em 1em 2em; font-size:0.9em; }
		@media all and (max-width: 599px) {
			.firstGuide,
			.addGuide,
			.localver, .latestver { font-size:0.9em; }
			.taskLog li { border-bottom: 1px solid #ddf; }
			a, b, i { word-break:break-all; }
		}
	</style>
</head>
<body class="<?php echo $AppTHEME; ?>">
	<div id="contents">
		<div id="header">
			<h1><span class="workname"><?php echo $AppWORKTITLE; ?></span><?php echo $AppSEP; ?><span class="appname">TegUp <?php echo $AppVERSION; ?></span></h1>
		</div>
		<div id="status">
			<?php echo $AppSTATUS; ?>
		</div>
		<div id="main">
			<?php echo $AppBODY; ?>
		</div>
		<div id="footer">
			<?php echo $AppFOOTER; ?>
		</div>
	</div>
	<p id="copyright">
		TegUp <?php echo $AppVERSION; ?>, Copyright &copy; 2023-<?php echo date("Y"); ?>, <a href="https://www.nishishi.com/">にしし/西村文宏</a>.
	</p>
</body>
</html>
<?php
// ----------------------
// エラー終了用画面の出力
// ----------------------
function errorEnd($msg)
{
	$err = errorMsg();
	$showSub = '';
	if( $err == '' ) {
		$showSub = '.sub { display:none; }';
	}

	$tlog = taskLog();
	$showLog = '';
	if( $tlog == '' ) {
		$showLog = '.log { display:none; }';
	}

	echo '<!DOCTYPE html>
<html lang="ja">
<head>
	<meta charset="utf-8"><meta name="robots" content="noindex"><meta name="viewport" content="initial-scale=1">
	<title>⛔ERROR - TegUp</title>
	<style>
		body { background-color:lightgray; }
		.page { border:5px solid crimson; background-color:white; outline:1px solid white; }
		h1 { margin:0; background-color:crimson; color:white; font-size:1.5em; padding:0 0 5px 0; }
		.body { padding:1em; border:1px solid crimson; outline:1px solid white; }
		.msg { border:1px solid crimson; background-color:lavenderblush; border-radius:1em; padding:1em; font-weight:bold; }
		.sub { border-top: 1px dashed gray; margin-top:1em; padding-top:1em; font-size:0.85em; } ' . $showSub . '
		.add { border:1px solid mediumblue; background-color:aliceblue; padding:0 1em; border-radius:0.3em; margin-bottom:2em; }
		.log { border-top: 1px dashed gray; margin-top:1em; padding-top:1em; font-size:0.85em; } ' . $showLog . '
		.rec { border:1px solid gray; background-color:whitesmoke; padding:0 1em; margin-bottom:2em; }
		.rec time { display:inline-block; margin-right:0.5em; color:darkblue; }
		.rec time::before { content: "["; }
		.rec time::after { content: "]"; }
		strong, .important, .msg p:first-child { color:crimson; }
		u { text-decoration:underline wavy pink; }
	</style>
</head>
<body>
	<div class="page">
		<h1>⛔ERROR - TegUp</h1>
		<div class="body">
			<p>何らかの問題があるため、処理を続行できません。詳細は以下の通りです。</p>
			<div class="msg">' . $msg . '</div>
			<p>上記に表示されているメッセージに従って対処して下さい。</p>
			<div class="sub">
				<p>なお、その他の細かなエラーが発生していた場合は、下記の枠に表示されます。</p>
				<div class="add">' . $err . '</div>
				<p>※赤枠に表示されているエラーは、「これ以上は処理を続行できない」致命的なエラーです。青枠に表示されているエラーは、「問題ではあるが処理は継続できる」程度のエラーです。<br>※エラーの発生位置によっては、一時的なファイルが生成されたまま放置されている可能性がありますのでご注意下さい。</p>
			</div>
			<div class="log">
				<p>作業ログが記録されていれば、下記の枠に表示されます。</p>
				<div class="rec">' . $tlog . '</div>
				<p>※上記のログに「作業後に自動削除されます」と表示されている場合、その作業が完遂していない場合は自動削除されずに<strong>残ったままになっている</strong>可能性があります。その場合は手動で削除して頂く必要がありますのでご注意下さい。<br>※問い合わせる際には、この画面に見えているすべての情報をお伝え下さい。キャプチャしても良いでしょう。</p>
			</div>
		</div>
	</div>
</body>
</html>';
	exit;
}

// --------------------
// 作業ログの蓄積と出力		引数があれば蓄積、引数がなければ出力。
// --------------------
function taskLog($addlog = null)
{
	global $outputLogToFile, $workinglogFileName;
	static $logmsg = '';

	if($addlog == null) {
		// 全出力
		if( $logmsg != '' ) {
			// 作業ログがあれば全出力
			return '<ul class="taskLog">' . $logmsg . '</ul>';
		}
		else {
			// 無ければ空文字を出力
			return '';
		}
	}
	else {
		// 追加(蓄積)
		$logmsg .= '<li><time>' . date("Y-m-d H:i:s") . '</time><span class="oneLog">' . $addlog . '</span></li>';
		if( $outputLogToFile == 1 ) {
			// ログをファイルにも出力する場合
			$content = date("Y-m-d H:i:s") . ' ' . $addlog . "\n";
			file_put_contents($workinglogFileName, $content, FILE_APPEND);
		}
		return;
	}
}

// ----------------------------
// エラーメッセージの蓄積と出力		引数があれば蓄積、引数がなければ出力。
// ----------------------------
function errorMsg($addmsg = null)
{
	static $errmsg = '';

	if($addmsg == null) {
		// 全出力
		if( $errmsg != '' ) {
			// エラーがあれば全出力
			return '<ul class="errorMsgs">' . $errmsg . '</ul>';
		}
		else {
			// 無ければ空文字を出力
			return '';
		}
	}
	else {
		// 追加(蓄積)
		$errmsg .= '<li>' . $addmsg . '</li>';
		return;
	}
}
?>
