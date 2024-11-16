# This program does not work alone.

# ================================================================== #
#  Fumy Versatile Control Set Ver 2.19.0 (UTF-8)        [fumycts.pl] #
# ================================================================== #
#  Copyright (C) Fumihiro Nishimura.(Nishishi) 2017-2024.            #
#                                                                    #
#  汎用っぽいコントロールライブラリ                                  #
#                                                                    #
#  このファイル内に設定項目はありません。そのまま使って下さい。      #
#                                                                    #
#  https://www.nishishi.com/                            [2024/07/06] #
# ================================================================== #

package fcts;
use strict;
use warnings;

my $pscheck = 1;
my $rcheck = 1;

# メイン側との共有変数群
our %flagDebug;
our $passfile;
our $cgi;
our $sessiontimeout;
our $keepsession;
our @userdata;		# ユーザ情報
our @catdata;		# カテゴリ情報
our $charcode;
our $cookiename;
our %aif;

my $vernum = 2019000;	# 2.19.0
#            ^  ^  ^

# ------------------------------------------	引数：0=全部読む／1=PWだけを読む／2:SESSIONだけを読む／3:FAILUREだけを読む	※行頭の種別「PASS=／SESSION=／FAILURE=」は出力しない
# パスワード・セッションID格納ファイルを読む	返値：(引数が1以上の場合) 読んだ内容の配列
# ------------------------------------------	返値：(引数が0の場合) 各項目の配列へのリファレンス群
sub loadpwsifile
{
	my $kind = shift @_ || 0;

	my @retPass = ();
	my @retSession = ();
	my @retFailure = ();

	# ファイルを読む
	&safetyfilename($passfile,1);	# 不正ファイル名の確認
	open( PWIN, $passfile ) or &errormsg("パスワード・セッションID格納ファイルが開けませんでした。");
	flock(PWIN, 1);
	my @alldata = <PWIN>;
	close PWIN;

	# 中身を分離
	foreach my $one (@alldata) {
		if(( $kind == 0 || $kind == 1 ) && ( $one =~ m/^PASS=(.+)/ )) {
			push( @retPass, $1 );
		}
		if(( $kind == 0 || $kind == 2 ) && ( $one =~ m/^SESSION=(.+)/ )) {
			push( @retSession, $1 );
		}
		if(( $kind == 0 || $kind == 3 ) && ( $one =~ m/^FAILURE=(.+)/ )) {
			push( @retFailure, $1 );
		}
	}

	if   ( $kind == 1 ) { return @retPass; }
	elsif( $kind == 2 ) { return @retSession; }
	elsif( $kind == 3 ) { return @retFailure; }
	else {
		return ( \@retPass, \@retSession, \@retFailure );
	}
}

# ------------------------------------------
# パスワード・セッションID格納ファイルへ出力	引数1：1=PWだけを更新／2:SESSIONだけを更新／3:FAILUREだけを更新　引数2：更新用配列
# ------------------------------------------
sub savepwsifile
{
	my $kind = shift @_ || &errormsg('ERROR:savepwsifile, No Kind Num.');
	my @tryarray = @_;
	my @ret;

	# 現状を読む
	my ($r1,$r2,$r3) = &loadpwsifile(0);
	my @passes   = @$r1;	# &loadpwsifile(1)
	my @sessions = @$r2;	# &loadpwsifile(2)
	my @failures = @$r3;	# &loadpwsifile(3)

	# 更新分の中身を作成
	foreach my $one (@tryarray) {
		if( $kind == 1 ) {		$one = 'PASS=' . $one;		}
		elsif( $kind == 2 ) {	$one = 'SESSION=' . $one;	}
		elsif( $kind == 3 ) {	$one = 'FAILURE=' . $one;	}
		else {					$one = 'ERROR=' . $one;		}
	}

	# 現状を記録用に戻す
	foreach my $one (@passes) {
		$one = 'PASS=' . $one;
	}
	foreach my $one (@sessions) {
		$one = 'SESSION=' . $one;
	}
	foreach my $one (@failures) {
		$one = 'FAILURE=' . $one;
	}

	# 出力用の全データ列を作成
	if( $kind == 1 ) {		push( @ret, (@tryarray,	@sessions,	@failures));	}	# PASSだけを更新
	elsif( $kind == 2 ) {	push( @ret, (@passes,	@tryarray,	@failures));	}	# SESSIONだけを更新
	elsif( $kind == 3 ) {	push( @ret, (@passes,	@sessions,	@tryarray));	}	# FAILUREだけを更新
	else {	push( @ret, (@passes, @sessions, @failures, @tryarray));			}	# エラー(何も更新しない)

	# 出力
	&safetyfilename($passfile,1);	# 不正ファイル名の確認
	open( PWOUT, "+< $passfile" ) or &errormsg("パスワード・セッションID格納ファイルへの出力に失敗しました。この処理が完了しないと認証情報を更新できません。");
	flock(PWOUT, 2);		# ロック確認。ロック
	truncate(PWOUT, 0);		# ファイルサイズを0バイトにする
	seek(PWOUT, 0, 0);		# ファイルポインタを先頭にセット
	print PWOUT join("\n", @ret);
	close PWOUT;			# closeすれば自動でロック解除
}

# ------------------------
# ◆パスワードの記録を更新	引数1：ユーザID、引数2：新しいPW(暗号化済み)文字列（※暗号化せずに空文字を渡せば削除扱い）
# ------------------------
sub updatepwdat
{
	my $userid  = shift @_ || &errormsg('ERROR:updatepwdat, No UserID.');
	my $newpass = shift @_ || '';

	# 現状を読む
	my @passes = &loadpwsifile(1);

	# 更新する
	my $upflag = 0;
	foreach my $one (@passes) {
		if( $one =~ m/^$userid,.+/ ) {
			# 一致すれば
			if( $newpass ne '' ) {
				# 文字列があれば更新
				$one = "$userid,$newpass";
			}
			else {
				# 文字列がなければ削除扱い
				$one = '';
			}
			$upflag = 1;
		}
	}

	# 更新がなければ(＋パスワード文字列がある場合のみ)追加する
	if(( $upflag == 0 ) && ( $newpass ne '' )) {
		push(@passes,"$userid,$newpass");
	}

	# 出力
	&savepwsifile( 1, @passes );	# PASSだけを更新
}

# -------------------------- #
# ◆セッションIDの生成・記録 #	記録形式： SESSION=有効期限,セッションID[改行]
# -------------------------- #
sub makesessionid
{
	my $reqestid = shift @_;

	# パスワード・セッションID記録ファイルの読み込み
	my @sessions = &loadpwsifile(2);

	# セッションIDの生成
	my $sessionid = 'si' . &getrandstr(36);		# 単純に36文字のランダムな英数字をセッションIDとする

	# セッションのタイムアウト時刻の生成
	my $timeouttime = time + $sessiontimeout;

	# 今回のセッションを記録
	my @ret;
	push( @ret, "$timeouttime,$sessionid,$reqestid" );

	# 無効になったセッションIDの削除
	foreach my $onesid ( @sessions ) {
		if( $onesid =~ m/^(\d+),.+/ ) {
			# セッションIDの有効期限を得て調べる
			if( $1 >= time ) {
				# 有効期限が来ていなければ記録継続
				push( @ret, $onesid );
			}
		}
	}

	# 出力
	&savepwsifile( 2, @ret );	# SESSIONだけを更新

	return $sessionid;
}

# -------------------- #	※読み取り専用でない限り、ここでCookieも更新するので、この関数よりも前に出力用ヘッダを書き出さないよう注意。（debug_ShowDebugStringsが1のときは、Cookieを更新できない。ただ、更新できなくてもCookieの有効期限が来るまでは問題なく処理できるハズ。）
# ◆認証：権限チェック #　　必須ではない引数readonlyflag： 値が1なら認証情報の更新をしない。
# -------------------- #　　返値：認証できたユーザID または空文字列 (※DEBUGフラグが立っていれば常に admin を返す／v2.15.0変更)
sub checkpermission
{
	my $readonlyflag = shift @_ || 0;

	return 'admin' if( $flagDebug{'NoAuthentication'} == 1 );	# for DEBUG

	# Cookieに格納されたセッションIDの有効性を確認(返値：有効=1/無効=0)
	my $sessionid = $cgi->cookie(-name=> $cookiename ) || '';
	if( $sessionid eq '' ) {
		# CookieにセッションIDがなければ「権限なし」として空文字を返す（＝セッションID一覧を調べるまでもない）
		return '';
	}

	if( $flagDebug{'ShowDebugStrings'} == 1 ) {
		print STDERR "SESSION ID is $sessionid.\n";
	}

	# パスワード・セッションID記録ファイルの読み込みと一致確認
	my @sessions = &loadpwsifile(2);
	my $res = '';

	foreach my $onesid ( @sessions ) {
		# 全セッションIDと比較
		if( $onesid =~ m/^(\d+),$sessionid,(.+)/ ) {	# $1=有効期限時刻、$2=ユーザID
			# 一致するセッションIDがあれば有効期限を確認
			if( $1 >= time ) {
				# 有効期限内であればOK
				if( $flagDebug{'ShowDebugStrings'} == 1 ) {	print STDERR ('[Limit]' . $1 . ' , [NOW]' . time . ' , (Leave)' . ($1 - time) . '.\n'); } # for DEBUG
				# 有効期限を更新
				my $nowlimit = $sessiontimeout + time;
				$onesid = "$nowlimit,$sessionid,$2\n";	# 「新有効期限,セッションID,ユーザ名」に書き換える
				# OK SIGN
				$res = $2;	# ユーザIDを返す
			}
		}
		# 一致するセッションがなければresは空文字のまま
	}

	# 認証に通過した上で、読み込み専用でなければ、認証情報を更新
	if(( $res ne '' ) && ( $readonlyflag != 1 )) {
		# セッション有効期限の更新を書き込み
		&savepwsifile( 2, @sessions );	# SESSIONだけを更新

		# セッション格納Cookieの更新
		print &makesessioncookie($sessionid);	# ここでCookieを直接出力しているので注意！
	}

	return $res;	# ユーザID文字列または空文字列を返す
}

# ------------------------------ #
# ◆認証：セッションCookieの生成 #	引数1：セッションID	※Cookie文字列を生成するだけで出力はしない。（CookieにユーザIDは含めない）
# ------------------------------ #
sub makesessioncookie
{
	my $sessionid = shift @_;

	my $cookie;
	if( $keepsession == 1 ) {
		# ブラウザを終了してもセッションを維持する場合
		# cookieの有効期限文字列を作成（セッション有効日数＋1日）※100日なら「+100d」という文字列になる
		my $expiredate = "+" . (( $sessiontimeout / (60 * 60 * 24) ) + 1 ) . "d";
		# セッションの有効期限＋1日を指定
		$cookie = $cgi->cookie(-name => $cookiename , -value => $sessionid , -expires => $expiredate );
	}
	else {
		# セッションはブラウザを終了するまで
		$cookie = $cgi->cookie(-name => $cookiename , -value => $sessionid );
	}
	return "Set-Cookie: $cookie; HttpOnly; SameSite=Lax\n";	# v1.8.0から「HttpOnly」と「SameSite=Lax」を強制付加。
}

# -------------------------- #
# ◆認証：セッション数を得る #
# -------------------------- #
sub sessioncount
{
	my @sessions = &loadpwsifile(2);	# セッション数をカウントするために読み込む
	return ($#sessions+1);
}

# ------------------------ #
# ◆認証：全セッション破棄 #
# ------------------------ #
sub breakallsessions
{
	my @breaks = ();
	my @sessions = &loadpwsifile(2);	# 削除セッション数を返すためだけに一旦読み込む

	# SESSIONだけを空っぽに更新
	&savepwsifile( 2, @breaks );

	return ($#sessions+1);
}

# ---------------------- #
# ◆認証：ログアウト処理 #	返値：Cookie削除用の文字列 （※この関数では直接は出力しない）
# ---------------------- #
sub logout
{
	# Cookieに格納されたセッションIDを得る
	my $sessionid = $cgi->cookie(-name=> $cookiename );

	# パスワード・セッションID記録ファイルの読み込みと一致確認
	my @sessions = &loadpwsifile(2);
	my $modflag = 0;

	foreach my $onesid ( @sessions ) {
		# 全セッションIDと比較
		if( $onesid =~ m/^(\d+),$sessionid,(.+)/ ) {
			# 一致するセッションIDがあれば有効期限を無効にする
			$onesid = "0,$sessionid,$2\n";
			$modflag = 1;
		}
	}

	if( $modflag == 1 ) {
		# セッション有効期限の更新を書き込み
		&savepwsifile( 2, @sessions );	# SESSIONだけを更新
	}

	# Cookieを削除 ※セッションを無効にした以上、Cookieの削除処理は必須ではないが、まあ立つ鳥跡を濁さず的に消しておく。(セッションを維持しない設定ならブラウザの終了と同時にCookieも破棄されるが、何らかの原因でセッションID記録ファイル側でIDを破棄できなかったときのためにCookie側も削除しておくと安全。)
	my $delcookie = $cgi->cookie(-name => $cookiename , -value => $sessionid , -expires => "-1d" );
	return "Set-Cookie: $delcookie\n";
}

# -------------------------- #	引数1：パスワード	引数2：ユーザID(※パスワードが1件も設定されていないかどうかを確認する際は、第2引数はなしで可。)
# ◆認証：パスワードチェック #	返値： -1:不一致 / 0:一致 / 1:パスワードなし / 2:パスワード登録が1件もない
# -------------------------- #	仕様変更(v2.4.10)：メイン側からハッシュ化キーを得ない。
sub checkpass
{
	my $trypass  = shift @_ || '';
	my $reqestid = shift @_ || '';

	# パスワード読み込み
	my @passes = &loadpwsifile(1);

	# パスワードが1つもない場合は「パスワード1件もなし」のサインを返す
	if( $#passes == -1 ) {
		return 2;
	}

	# ユーザIDの指定がない場合は常に「不一致」を返す
	if( $reqestid eq '' ) { return -1; }

	# パスワード文字列があるかどうかで分岐
	if( $trypass ne '' ) {
		# ある場合

		# パスワード一致チェックループ
		foreach my $onepass ( @passes ) {

			# 記録パスワードから種を抽出
			my @separatedat = split(/,/, $onepass);		# 記録データをIDとPWに分割
#			my $salt = substr($separatedat[1], 0, 2);	# そのPW部分から種(先頭の2文字)を抽出
			my $salt = $separatedat[1] =~ /^(\$1\$.*\$).+/ ? $1 : substr($separatedat[1], 0, 2);	# PW部分から種を抽出(MD5形式ならその方法で、違うならDES方式と解釈して先頭の2文字を抽出)

			# その種でユーザ入力文字列を暗号化
			my $tcpass = crypt($trypass,$salt);

			# 記録パスワードデータと比較
			my $trydata = $reqestid . ',' . $tcpass;	# IDとPASSを合体させた比較用文字列を作る
			if( $onepass eq $trydata ) {
				# 一致すれば
				return 0;
			}

			# print STDERR "SALT: $salt / CRYPTED: $tcpass / ONEPASS: $onepass cf $trydata \n";		# for DEBUG

		}
		# 一致しなければ
		return -1;
	}
	else {
		# ない場合

		# ID一致チェック
		foreach my $onepass ( @passes ) {
			if( $onepass =~ m/^$reqestid,.+/ ) {
				# 一致すれば：パスワードが設定されているにもかかわらず無入力だったので拒否
				return -1;
			}
		}
		# 何も一致しなければ：パスワードが設定されていない
		return 1;
	}
}

sub lcc
{
	my $trylcc = shift @_ || '';
	if( $trylcc =~ /^\w{5}[-t]\w{5}[-od]\w{5}$/ ) {
		return 1;	# 条件に合致
	}
	return 0;	# 条件外
}

# -----------------------------
# ◆認証：DES/MD5両対応Crypt
# -----------------------------
sub desmd5encrypt
{
	my $plain = shift @_ || '';
	my $salt  = shift @_ || &getrandstr(2);		# 種は2桁固定

	# 最初にMD5方式で実行し、MD5式暗号なら返す。NGだったらDES方式で実行して返す
	return crypt($plain, '$1$' . $salt . '$') =~ /^(\$1\$.+)/ ? $1 : crypt($plain, $salt);
}

# ------------------------------
# ◆認証：指定IDの失敗情報を返す		引数：ID名
# ------------------------------		返値：情報の配列 (※該当情報がなければ、空の配列)
sub checkfailure
{
	my $checkid = shift @_ || &errormsg('ERROR:checkfailure, ID Required.');

	# パスワード・セッションID記録ファイルの読み込み
	my @failures = &loadpwsifile(3);

	my @ret = ();
	$checkid = quotemeta($checkid);

	foreach my $onefail ( @failures ) {
		if( $onefail =~ m/^$checkid,.+/ ) {
			# 指定IDの失敗情報があればそれを返す
			@ret = split(/,/, $onefail);
			last;	#  同一IDに対する失敗情報は1つしかないことが前提。2つ以上あっても1つ目以後は無視する
		}
	}

	return @ret;
}

# ------------------------------------		引数1：更新するID名、引数2：成否の種別(-1=失敗、1=成功)、引数3：条件ロックの分数
# ◆認証：指定IDの失敗情報を記録・更新		（引数1・2が省略された場合は全体の更新だけをする。全引数が省略されたら何もしない）
# ------------------------------------		返値：なし
sub updatefailurerec
{
	my $checkid = shift @_ || '';
	my $sucfail = shift @_ || 0;
	my $loginlockminutes = shift @_ || 0;		# 引数3：ロック分数		$setdat{'loginlockminutes'}

	# パスワード・セッションID記録ファイルの読み込み
	my @failures = &loadpwsifile(3);

	# 更新するID(あれば)を検索用文字列にしておく
	my $qmcid = quotemeta($checkid);
	my $updatedflag = 0;

	foreach my $onefail ( @failures ) {
		# ----------------------------
		# ロック時間超過レコードの削除
		if( $loginlockminutes > 0 ) {
			# 条件ロック分数の指定があれば、判定して更新する
			my @failinfo = split(/,/, $onefail);
			my $faildate = $failinfo[2];	# 前回の失敗時刻
			my $locksec = $loginlockminutes * 60;		# ロック継続する分数を秒数に変換
			if( time >= ($locksec + $faildate) ) {
				# 前回の失敗から、ロック継続する秒数が経過していれば削除
				$onefail = '';
			}
		}
		# --------------------------
		# 指定IDの更新が必要なら探す
		if(( $checkid ne '' ) && ( $onefail =~ m/^$qmcid,.+/ )) {
			# 指定IDの失敗情報があれば更新
			my @failinfo = split(/,/, $onefail);
			if( $sucfail == -1 ) {
				# 失敗情報を更新する場合
				my $failtime = $failinfo[1] + 1;	# これまでのログイン失敗回数に1を加算
				# 新しいレコードを作る
				my $newrec = $checkid . ',' . $failtime . ',' . time;	# ID,失敗回数,時刻
				# それを記録(配列を更新)
				$onefail = $newrec;
			}
			elsif( $sucfail == 1 ) {
				# 成功したので失敗情報を消す場合
				$onefail = '';
			}
			$updatedflag = 1;
		}
	}

	# 指定IDの失敗情報の記録が必要な場合で、更新データがなかった場合は、新規に追加する
	if(( $checkid ne '' ) && ( $sucfail == -1 ) && ( $updatedflag == 0 )) {
		# 新規レコードを作る
		my $newrec = $checkid . ',1,' . time;	# ID,失敗回数=1,時刻
		# 配列に追加する
		push( @failures, $newrec );
	}

	# 配列の中から空の要素を削除する
	@failures = grep { $_ ne '' } @failures;		# grepで「空ではない要素」だけを抜き出す

	# 出力
	&savepwsifile( 3, @failures );	# FAILUREだけを更新

	return;
}

# ----------------------------
# ◆認証：ロック中かどうか判別	引数1：確認するユーザID、引数2～5：ロック条件と設定( $setdat{'loginlockshort'},$setdat{'loginlockrule'},$setdat{'loginlocktime'},$setdat{'loginlockminutes'} )
# ----------------------------	返値1：0=ロック中ではない、1以上=ロックの残り時間、返値2：ロックの種類(0:なし/1:短秒ロック/2:条件ロック)
sub islocked
{
	my $checkid = shift @_ || &errormsg('ERROR:islocked, ID Required.');	# 引数1：確認するユーザID
	my $loginlockshort	= shift @_ || 0;		# 引数2：短秒ロック設定	$setdat{'loginlockshort'}
	my $loginlockrule	= shift @_ || 0;		# 引数3：条件ロック設定	$setdat{'loginlockrule'}
	my $loginlocktime	 = shift @_ || 0;		# 引数4：失敗不許容回数	$setdat{'loginlocktime'}
	my $loginlockminutes = shift @_ || 0;		# 引数5：ロック分数		$setdat{'loginlockminutes'}

	# ロック条件の設定を確認
	if(( $loginlockshort == 0 ) && ( $loginlockrule == 0 )) {
		# ロックが不要な設定なら、確認するまでもなくロック中ではない
		return (0,0);
	}

	# 指定IDの失敗情報を得る
	my @failinfo = &checkfailure( $checkid );

	# 失敗情報があれば判定する
	if( @failinfo ) {
		my $failtime = $failinfo[1];	# ログイン失敗回数
		my $faildate = $failinfo[2];	# 前回の失敗日時

		# 前回の失敗からの経過時間(秒数)を計算しておく
		my $pastsec = time - $faildate;
		my $locksec = $loginlockminutes * 60;		# ロック継続する分数を秒数に変換

		# 判定2：ログインに連続で失敗したら、指定条件でロックする
		if( $loginlockrule == 1 ) {
			# 条件ロックが有効なら
			if( $failtime >= $loginlocktime ) {
				# 失敗不許可回数に達していたら
				if( $pastsec < $locksec ) {
					# 前回の失敗から、ロック継続する秒数が経過していなければロック
					return (($locksec - $pastsec), 2);
				}
			}
		}

		# 判定1：ログインに失敗するたびに、直後の約2秒間だけロックする
		if(( $failtime > 0 ) && ( $loginlockshort == 1 )) {
			# 失敗回数が1以上で、2秒間ロックが有効なら
			if( $pastsec < 2 ) {
				# 前回の失敗時刻から、まだ2秒未満しか経過していないならロック
				return (($locksec - $pastsec), 1);
			}
		}

	}

	# ロック中ではない
	return (0,0);
}

# ------------------------
# ◆汎用パスワードチェック		引数1：種付きハッシュ済みPASS、引数2：試行PASS
# ------------------------		返値：1=一致、0=不一致
sub encryptcheck
{
	my $orgstr = shift @_ || '';
	my $trystr = shift @_ || '';

	my $salt = $orgstr =~ /^\$1\$(.*)\$.+/ ? $1 : substr($orgstr, 0, 2);	# 種付きハッシュ済みPASSから種を抽出(MD5形式ならその方法で『種部分だけ』を抽出、違うならDES方式と解釈して先頭の2文字を抽出)
	my $trypass = &desmd5encrypt( $trystr, $salt );

	# 一致確認
	if( $trypass eq $orgstr ) {
		return 1;
	}
	return 0;
}

# --------------------
# ◆IPアドレスチェック		引数1：IPアドレスの許可リスト(縦棒区切り=psv)、引数2：確認するIPアドレス(省略すると環境変数から取得)
# --------------------		返値：1=一致、0=不一致、-1=リストなし、9=IP取得失敗
sub ipwhitecheck
{
	my $ippsv = shift @_ || return -1;
	my $nowip = shift @_ || $ENV{REMOTE_ADDR} || return 9;

	my @ips = split(/\|/,$ippsv);		# 縦棒で分割
	foreach my $oneip (@ips) {
		$oneip = trim($oneip);	# 前後の空白は削除しておく
		if( $oneip =~ m/[^0-9\\.]/ ) {
			# 数字とドット以外の文字列があれば無視
			next;
		}
		# チェックIPがリストに含まれているかどうか
		$oneip = quotemeta($oneip);
		if( $nowip =~ m/^$oneip/ ) {
			# 含まれていれば
			return 1;
		}
	}

	return 0;
}


# -----------------------------
# ◎REF:セッション有効時間の計算		引数に「日」の数値を受け取り、「秒」に変換して返す。
# -----------------------------
sub calcsessionlimit
{
	my $limd = shift @_ || 1;

	# セッション有効時間の秒変換
	my $lims = int( $limd * 86400 );	# 時間指定を秒数に変換(60×60×24)：整数で！

	# 安全確認（強制修正）
	if( $lims < 3600 ) { $lims = 3600; }	# セッション維持が1時間未満なら1時間へ修正
	elsif( $lims > 31622400 ) { $lims = 31622400; }	# 1年より長ければ1年に修正

	return $lims;
}

# 														=== ▼独自区切り形式の汎用操作 ===

# -------------------------------
# ◆OSV：独自区切り情報の分解格納	引数：<>と<,>で区切られた生データ
# -------------------------------
sub tidyDat
{
	my $rawDat = shift @_ || '';			# 引数に何もないことはない前提(エラーにはしないが)
	my @retdat = ();

	my @itemlist = split(/<,>/,$rawDat);	# 1件単位で分離
	my $i = 0;
	foreach my $oneinfo (@itemlist) {
		@{$retdat[$i]} = split(/<>/,$oneinfo); # 1件内データを分離	（※この書き方だと要素数が入るだけで配列にならない）
		$i++;
	}

	return @retdat;
}

# 														=== ▼ユーザID操作 ===

# ---------------------------------
# ◆UID：ユーザ情報を更新/追加/削除	引数1：対象ID、2：name、3：icon、4：permission、5：tryintro		（※権限が0だったら削除）
# ---------------------------------
sub makeLineForUserDat
{
	my $tryid			= shift @_ || '';
	my $tryname			= shift @_ || '';
	my $tryicon			= shift @_ || '';
	my $trypermission	= shift @_ || 0;
	my $tryintro		= shift @_ || '';

	my @newids;
	my $ret = '';

	# ユーザ情報2次元配列を全ループして更新(or追加/削除)
	my $wflag = 0;
	for my $i ( 0 .. $#userdata ) {
		if( $userdata[$i][0] eq $tryid ) {
			# 指定のIDを発見したら
			if( $trypermission > 0 ) {
				# 権限の指定があれば更新
				push(@newids, "$tryid<>$trypermission<>$tryname<>$tryintro<>$tryicon<>");
			}
			else {
				# 権限の指定がなければ削除
				#（何も処理しない）
			}
			$wflag = 1;		# 作業済みフラグを立てる
		}
		else {
			# 別のIDだったらそのまま追加
			push(@newids, "$userdata[$i][0]<>$userdata[$i][1]<>$userdata[$i][2]<>$userdata[$i][3]<>$userdata[$i][4]<>");
		}
	}
	if( $wflag == 0 ) {
		# まだ何もしていなければ新規追加なので末尾に追加する
		push(@newids, "$tryid<>$trypermission<>$tryname<>$tryintro<>$tryicon<>");
	}

	# ユーザ情報をデータファイルに記録するための1行文字列を生成
	$ret = join("<,>",@newids);

	# それを返す。
	return $ret;
}

# -------------------------------
# ◆UID：ユーザIDから表示名を得る	引数1：ユーザID、引数2：得たい情報番号(1=権限,2=表示名,3=プロフィール,4=アイコン)
# -------------------------------	返値：得たいデータ（該当なしの場合は「空文字列」を返す）
sub getUserDetail
{
	my $searchid = shift @_ || '';
	my $detailno = shift @_ || 0;

	if( !$searchid ) { &errormsg('getUserDetail：ユーザIDの指定がない（このエラーが出たら設定ファイルを作者に送って下さい。もしくは設定(ini)ファイルを初期化すると解決するかも知れません。）'); }
	if( $detailno < 1 || $detailno > 4 ) { &errormsg('getUserDetail：得たい情報番号が不正'); }

	for my $i ( 0 .. $#userdata ) {
		if( $userdata[$i][0] eq $searchid ) {
			return $userdata[$i][$detailno];
		}
	}

	return '';
}

# -------------------------
# ◆UID：ユーザリストを得る		返値：UserID,表示名
# -------------------------
sub getUserList
{
	my @ret;

	# 全ユーザをループ
	for my $i ( 0 .. $#userdata ) {
		push( @ret, "$userdata[$i][0]<>$userdata[$i][2]" );
	}

	return @ret;
}

# -------------------------
# ◆UID：ユーザ一覧表を表示		引数：ユーザIDをリンクにする場合のhref文字列
# -------------------------
sub getUserTable
{
	my $linkhref = shift @_ || '';
	my @ret;

	my @pws = &loadpwsifile(1);	# パスワード一覧を得る

	push( @ret, '<table class="userlist standard"><tr><th>User ID</th><th>表示名</th><th>権限</th><th>紹介</th><th>パスワード</th></tr>' );

	# 全ユーザをループ
	for my $i ( 0 .. $#userdata ) {

		# 必要ならリンク文字列を作る
		my $ltag1 = '';
		my $ltag2 = '';
		if( $linkhref ne '' ) {
			# リンク文字列を作る
			$ltag1 = qq|<a href="$linkhref&amp;userid=| . &forsafety($userdata[$i][0]) . qq|">|;
			$ltag2 = '</a>';
		}

		# パスワードの存在確認
		my $expw = '<strong style="color:red;">未設定</strong>';
		foreach my $opw (@pws) {
			if( $opw =~ m/^$userdata[$i][0],/ ) {
				$expw = '設定済み';
				last;
			}
		}

		push( @ret, '<tr><td>' . $ltag1 . &forsafety($userdata[$i][0]) . $ltag2 . '</td><td>' . &forsafety($userdata[$i][2]) . '</td><td>' . 'Lv.' . &forsafety($userdata[$i][1]) . '</td><td>' . &forsafety($userdata[$i][3]) . '</td><td>' . $expw . '</td></tr>' );
	}

	push( @ret, '</table>' );

	return @ret;
}

# --------------------------------------------
# ◆UID：ログインフォーム用のID/PW入力欄を作成		引数1：パスワードなしユーザを拒否(0:しない/1:する)
# --------------------------------------------
sub getLoginIDPWForm
{
	my $nopwuser = shift @_ || 0;

	my $idform = '';
	my $pwform = '';

	# パスワードの設定状態を確認(全く未設定なら2が返る)
	my $passexist = &checkpass();

	if( $passexist == 2 ) {
		# パスワードが設定されていなければ

		if(( $#userdata > 0 ) || ( $#userdata == 0 && &getUserDetail('admin',1) eq '' )) {
			# ユーザ数が2つ以上の場合
			# または、ユーザ数が1つだが、adminというIDがない場合
			# ユーザIDフォームは作るが、パスワードは無条件
			$idform .= &getLoginIDsForm();
			$pwform = '<span class="passline nopass"><label class="authlabel" for="trystring">Password:</label> <input type="password" class="passinput" value="" name="trystring" disabled placeholder="(入力不要)"></span>';
		}
		else {
			# それ以外の場合(＝ユーザ数が1つで、それがadminの場合)
			# 無条件ログイン用フォームを作成
			$idform = '<input type="hidden" value="admin" name="requestid">';
			$pwform = '<input type="hidden" value="" name="trystring">';
		}

	}
	else {
		# パスワードが既に設定されていればログインフォームを表示
		$idform .= &getLoginIDsForm($nopwuser);
		$pwform = '<span class="passline"><label class="authlabel" for="trystring">Password:</label> <input type="password" class="passinput" value="" name="trystring" id="trystring"></span>';
	}

	return ( $idform . $pwform );
}

# ユーザIDのセレクトボックスを作る
sub getLoginIDsForm
{
	my $nopwuser = shift @_ || 0;

	my $ret = '';
	$ret = '<span class="idline"><label class="authlabel" for="requestid">User ID:</label> <select name="requestid" id="requestid" class="idselect">';
	for my $i ( 0 .. $#userdata ) {
		if( $nopwuser >= 1 && &checkpass('',$userdata[$i][0]) >= 1 ) {
			# パスワードなしユーザを拒否する設定の場合で、指定ユーザのパスワードがない場合は、ループを次へ
			next;
		}
		$ret .= '<option value="' . &forsafety($userdata[$i][0]) . '">' . &forsafety($userdata[$i][2]) . '(' . &forsafety($userdata[$i][0]) . ')</option>';
	}
	$ret .= '</select></span><br>';
	return $ret;
}


# 														=== ▼カテゴリ操作 ===

# -----------------------------------	引数1：ID、引数2：表示名、3：概要文、4：親カテゴリID、5：該当個数、6：掲載順序、7：アイコンURL		※引数1(ID)が「*ZERORESET」だったら該当件数を0にリセット。引数6(順序)が「DEL」だったら削除。
# ◆CAT：カテゴリ情報を更新/追加/削除	引数2～7は、値が「＾維」だったら前の値を維持する
# -----------------------------------	返値：カテゴリ情報をデータファイルに記録するための1行文字列
sub makeLineForCategoryDat
{
	my $tryid		= shift @_ || '';
	my $tryname		= shift @_ || '';
	my $trydscrpt	= shift @_ || '';
	my $tryparent	= shift @_ || '-';	# 親カテゴリがない場合（＝自分が最上階層の場合）は「-」を記録する仕様
	my $tryposts	= shift @_ || 0;
	my $tryorder	= shift @_ || 1;	# 順序指定がない場合は1と解釈
	my $tryiconurl	= shift @_ || '';

	my $ret = '';

	# …………………………………………………………………………………………………………
	# Step.1：まずは追加/編集/削除：ユーザ情報2次元配列を全ループして更新(or追加/削除)
	# …………………………………………………………………………………………………………
	my @newids;	# とりあえず追加/編集/削除する配列
	my @orders;	# 掲載順序の記録用
	my $wflag = 0;
	for my $i ( 0 .. $#catdata ) {
		if( $catdata[$i][0] eq $tryid ) {
			# 指定のIDを発見したら
			if( $tryorder ne 'DEL' ) {
				# 削除フラグがなければ更新

				# 各値が「＾維」だったら以前の値を維持する
				if( $tryname    eq '＾維' ) { $tryname   = $catdata[$i][1]; }
				if( $trydscrpt  eq '＾維' ) { $trydscrpt = $catdata[$i][2] || ''; }		# 値がなければ空文字
				if( $tryparent  eq '＾維' ) { $tryparent = $catdata[$i][3]; }
				if( $tryposts   eq '＾維' ) { $tryposts  = $catdata[$i][4]; }
				if( $tryorder   eq '＾維' ) { $tryorder  = $catdata[$i][5]; }
				if( $tryiconurl eq '＾維' ) { $tryiconurl= $catdata[$i][6] || ''; }		# 値がなければ空文字

				$tryorder = &nozenkaku($tryorder);
				push(@newids, "$tryid<>$tryname<>$trydscrpt<>$tryparent<>$tryposts<>$tryorder<>$tryiconurl<>");
				push(@orders, $tryorder);
			}
			$wflag = 1;		# 作業済みフラグを立てる
		}
		else {
			# 別のIDだったらそのまま追加
			if( $tryid eq '*ZERORESET' ) {
				#IDが「*ZERORESET」だったら該当件数を0にリセット (※元の配列の値を更新しているので、保存しなくても直後の処理には反映されるハズ。)
				 $catdata[$i][4] = 0;
			}
			$catdata[$i][5] = &nozenkaku($catdata[$i][5]);
			$catdata[$i][2] = $catdata[$i][2] || '';	# 値がなければ空文字
			$catdata[$i][6] = $catdata[$i][6] || '';	# 値がなければ空文字
			push(@newids, "$catdata[$i][0]<>$catdata[$i][1]<>$catdata[$i][2]<>$catdata[$i][3]<>$catdata[$i][4]<>$catdata[$i][5]<>$catdata[$i][6]<>");
			push(@orders, $catdata[$i][5] );
		}
	}
	if(( $wflag == 0 ) && ( $tryid ne '*ZERORESET' )) {
		# まだ何もしていなければ新規追加なので(とりあえず)末尾に追加する (※該当個数は「未集計」にする)	※IDが「*ZERORESET」の場合は何もしない。
		$tryorder = &nozenkaku($tryorder);
		push(@newids, "$tryid<>$tryname<>$trydscrpt<>$tryparent<>未集計<>$tryorder<>$tryiconurl<>");
		push(@orders, $tryorder);
	}

	# ………………
	# 削除の後処理：削除されたIDを親カテゴリに持つIDを最上階層に引き上げておく
	# ………………
	if( $tryorder eq 'DEL' ) {
		for my $i ( 0 .. $#newids ) {
			$newids[$i] =~ s/<>$tryid<>/<>-<>/;		# 親カテゴリIDを、最上階層「-」に修正する
		}
	}

	# ……………………………………………
	# Step.2：掲載順序の小さい順にソート
	# ……………………………………………
	my @sortedids;	# @newids の中身を掲載順序の小さい順に並べ替えた結果を格納

	# @orders を標準的な方法でソートした結果を @sorted に入れる。
	my @sorted = sort {$a <=> $b} @orders;

	# @sorted をforeachでループして、値(＝順序数値)を @orders の中から探す。for文で要素数だけループすれば済む。(無限ループにはならない)
	foreach my $num (@sorted) {
		for my $i ( 0 .. $#orders ) {
			if( $num eq $orders[$i] ) {
				# 注：文字として比較する（空にした要素を 0 だと解釈しないように）
				# 値が一致したら：一致した @orders の添え字番号を使って、 @newids のどれを読めば良いかを特定する。(同じ添え字番号を使えば良い)
				# その $newids[$i] を @sortedids にpushする。
				push(@sortedids, $newids[$i]);
				# 元データは消す(同じデータを拾わないように)
				$newids[$i] = '';
				$orders[$i] = '';
				# ループを抜ける
				last;
			}
		}
	}

	# 以上でソート完了。
	# この時点で @sortedids 配列の中に「掲載順序の小さい順に並べ替えたカテゴリデータ(階層は未考慮)」が入っている。

	# ………………………………………
	# Step.3：階層を考慮して並べ替え
	# ………………………………………
	my @layeringids;	# @sortedids の中身を階層考慮順序に並べ替えた結果を格納

	# 再帰関数 (※この関数の外側にある変数を参照しているため、無名関数として作っておかないと2度目の実行時以降は変数を共有できなくなる。「Variable "$hoge" will not stay shared」のワーニングが出る。)
	my $constructCatTree;
	$constructCatTree = sub {
		my $parentCatId = shift @_ || '-';	# 走査する親カテゴリID（初回実行時は最上階層カテゴリを示す「-」にすることで第1階層を作る）

		# 最上階層を作るときには、ソート結果格納用の配列の中身をクリアしておく
		if( $parentCatId eq '-' ) {
			@layeringids = ();
		}

		# 再帰呼び出しの終了条件（@sortedidsの中身が全部カラになったら終わる）
		# foreachでループして中身が全部空かどうかを調べる処理を書く
		### 終了条件は書かなくても無限ループにはならないのでは？（使った要素を空要素に置き換えているので、いずれは全部空になるから）

		for my $i ( 0 .. $#sortedids ) {
			# 指定親要素のカテゴリだけを抜き出して追加する
			if( $sortedids[$i] =~ m/.+<>.+<>.*<>$parentCatId<>/i ) {	# 親カテゴリは各データの4番目に記録されていることが前提
				# 親要素が指定カテゴリだったら記録
				push(@layeringids,$sortedids[$i]);
				# いま抜き出したカテゴリ名を得る
				my $onecat = substr($sortedids[$i], 0, index($sortedids[$i], '<>'));		# 先頭から <> の出現する直前の文字までを得る＝カテゴリ名
				# 記録済みの元データは消しておく
				$sortedids[$i] = '';
				# いま抜き出したカテゴリを親カテゴリとするカテゴリがないか走査する（再帰）
				$constructCatTree->($onecat);
			}
		}
	};
	$constructCatTree->();

	# カテゴリ情報をデータファイルに記録するための1行文字列を生成
	$ret = join("<,>",@layeringids);

	# カテゴリが1件もない場合は、区切り文字単独を挿入する
	if( $ret eq '' ) {
		$ret = '<,>';
	}

	# それを返す。
	return $ret;
}

# --------------------------
# ◆CAT：カテゴリツリーを表示		引数1：カテゴリのリンクに追加する文字列(必要なら)、引数2：フラグ
# --------------------------		返値：カテゴリツリーのHTMLソース
sub getCategoryTree
{
	my $addlinkstr = shift @_ || '';
	my $catflags = shift @_ || '';
	my $allowhtmlopt = shift @_ || 0;

	my $retTreeHtml = '';
	my $listDeepCounter = 0;

	# カテゴリフラグの値チェック
	if( $catflags !~ m/[I|T|D]/ ) {
		# フラグIかTかDのどれも含まれていないならデフォルト値にする
		$catflags = '<IT>C';	# デフォルトは「リンク（アイコン＋テキスト）＋カウント値」
	}

	my $safetyi = 0;	# 再帰呼び出しの無限ループを防ぐ安全策

	# 再帰関数 (※この関数の外側にある変数を参照しているため、無名関数として作っておかないと2度目の実行時以降は変数を共有できなくなる。「Variable "$hoge" will not stay shared」のワーニングが出る。ただ、この関数の場合は2度は実行しないと思うけど。)
	my $makeCatTreeStructure;
	$makeCatTreeStructure = sub {
		my $checkParentCatId = shift @_ || '-';	# 走査する親カテゴリID（初回実行時は最上階層カテゴリを示す「-」にすることで第1階層を作る）

		# 最上階層を作るときには、
		if( $checkParentCatId eq '-' ) {
			$listDeepCounter = 1;	# ツリーの深さをカウントする変数を1にしておく
		}

		# 単一階層でのみ使う一時変数
		my $thisLayerHtml = '';			# この階層分のHTML
		my $thisLayerCount = 0;			# この階層での挿入個数

		# リストOPEN
		$thisLayerHtml .= '<ul class="cattree depth' . $listDeepCounter . '">';

		# 全カテゴリをループ
		for my $i ( 0 .. $#catdata ) {

			# カテゴリの情報を分解（※安全化はしていないので出力時に面倒を見ること）
			my $catid		= $catdata[$i][0];
			my $catname		= $catdata[$i][1];
			my $catdscrpt	= $catdata[$i][2];
			my $parentcat	= $catdata[$i][3] || '-';
			my $catposts	= $catdata[$i][4] || '0';
			my $catorder	= $catdata[$i][5];
			my $caticonurl	= $catdata[$i][6] || '';

			if( lc($checkParentCatId) eq lc($parentcat) ) {
				# 親要素が指定カテゴリだったら記録
				$thisLayerCount++;

				# カテゴリclass文字列を生成しておく
				my $catclass = 'cat-' . &forsafety($catid);

				# 組み立て用の各要素を作っておく
				# 要素 T ：カテゴリ名テキスト（Text）
				# 要素 I ：カテゴリアイコン（Icon）
				# 要素 C ：カテゴリ該当数（Count）	※小文字だとカッコなし
				# 要素 D ：カテゴリ概要文（Description）
				# 要素 B ：改行（<br>タグ）
				# 要素 <>：当該カテゴリ限定ページへのリンク

				# 要素T：カテゴリ名テキスト（Text）
				my $catPartT = '<span class="cattext ' . $catclass . '">' . &forsafety($catname) . '</span>';

				# 要素I：アイコンがあれば表示HTMLを作る
				my $catPartI = '';
				if( $caticonurl ne '' ) {
					$catPartI = '<span class="caticon"><img src="' . &forsafety($caticonurl) . '" alt="' . &forsafety($catname) . '" class="' . $catclass . '"></span>';
				}

				# 要素C：カテゴリ該当数（Count）
				my $catPartC = '<span class="num">(' . $catposts . ')</span>';

				# 要素c：カテゴリ該当数（Count）カッコなし
				my $catPartc = '<span class="num">' . $catposts . '</span>';

				# 要素D：カテゴリ概要文（Description）
				my $cpD;
				if( $allowhtmlopt == 1 ) {
					# HTMLを許可する場合はそのまま採用
					$cpD = $catdscrpt;
				}
				else {
					# HTMLを許可しない場合は安全化して使用
					$cpD = &forsafety($catdscrpt);
				}
				
				my $catPartD = '<span class="catdescription">' . $cpD . '</span>';

				# リンク用文字列を作る
				my $linkhref = '?cat=' . &forsafety($catid);
				if( $addlinkstr ne '' ) {
					# 追加があれば加える
					$linkhref .= '&amp;' . &forsafety($addlinkstr);
				}

				# フラグから出力ソースを作成
				my $catsource .= '';
				foreach my $flag (split //, $catflags) {
					# フラグがあるだけループ
					if(    $flag eq 'T' )	{ $catsource .= $catPartT; }
					elsif( $flag eq 'I' )	{ $catsource .= $catPartI; }
					elsif( $flag eq 'C' )	{ $catsource .= $catPartC; }
					elsif( $flag eq 'c' )	{ $catsource .= $catPartc; }
					elsif( $flag eq 'D' )	{ $catsource .= $catPartD; }
					elsif( $flag eq 'B' )	{ $catsource .= '<br>'; }
					elsif( $flag eq '<' )	{ $catsource .= '<a href="' . $linkhref . '" class="catlink ' . $catclass . '">'; }
					elsif( $flag eq '>' )	{ $catsource .= '</a>'; }
					elsif( $flag eq '"' )	{ $catsource .= '&quot;'; }
					elsif( $flag eq "'" )	{ $catsource .= '&apos;'; }
					else { $catsource .= $flag; }
				}

				$thisLayerHtml .= '<li class="catbranch ' . $catclass . '">' . $catsource;

				# いま抜き出したカテゴリを親カテゴリとするカテゴリがないか走査する（再帰）
				$listDeepCounter++;		# リストを増やそうとしているので、階層カウントに1加えておく (※結果的に増やさない場合もあるが、その場合も後から1引くので問題ない)
				if( $safetyi++ < 250 ) {	# 再帰呼び出しが無限ループになるのを防ぐ安全策(MAX:250ループ)
					$thisLayerHtml .= $makeCatTreeStructure->($catid);	# 再帰呼出
				}
				else {
					$thisLayerHtml .= '<b>無限ループ防止</b>'
				}
				# 閉じタグ
				$thisLayerHtml .= '</li>';
			}
		}

		# リストCLOSE
		$thisLayerHtml .= '</ul>';
		$listDeepCounter--;		# リストを閉じるので、ツリーの深さをカウントする変数からも1を引いておく (※出力内容がなくて、HTMLではリストを閉じない場合もあるが、その場合でも深さのカウントは事前に1増やされているので、ここで減らしておく必要がある)

		# この階層に1項目以上あれば、生成内容を出力する
		if( $thisLayerCount > 0 ) {
			return $thisLayerHtml;
		}
		return '<!-- No items on this layer -->';
	};
	$retTreeHtml = $makeCatTreeStructure->() . '<!-- End of Tree -->';

	return $retTreeHtml;
}

# --------------------------
# ◆CAT：カテゴリ一覧表を表示		引数：カテゴリをリンクにする場合のhref文字列
# -------------------------^
sub getCategoryTable
{
	my $linkhref = shift @_ || '';
	my @ret;

	push( @ret, '<table class="catlist standard"><tr><th>カテゴリID</th><th>カテゴリ名</th><th style="font-size:0.5em;">アイコン</th><th>概要文</th><th>親カテゴリID</th><th>該当数</th><th>掲載順</th></tr>' );

	# 全カテゴリをループ
	for my $i ( 0 .. $#catdata ) {

		# 必要ならリンク文字列を作る
		my $ltag1 = '';
		my $ltag2 = '';
		if( $linkhref ne '' ) {
			# リンク文字列を作る
			$ltag1 = qq|<a href="$linkhref&amp;catid=| . &forsafety($catdata[$i][0]) . qq|">|;
			$ltag2 = '</a>';
		}

		my $catid		= &forsafety( $catdata[$i][0] );
		my $catname		= &forsafety( $catdata[$i][1] );
		my $catdscrpt	= &forsafety( $catdata[$i][2] );
		my $parentcat	= &forsafety( $catdata[$i][3] ) || '-';
		my $catposts	= &forsafety( $catdata[$i][4] ) || '0';
		my $catorder	= &forsafety( $catdata[$i][5] );
		my $caticonsrc	= &forsafety( $catdata[$i][6] );

		# 階層サインを反映
		if( $parentcat ne '-' ) {
			# 親要素が存在するようなら、階層サインを加える
			$ltag1 = '&nbsp;' . $ltag1;
		}

		# アイコン表示
		my $caticon = '';
		if( $caticonsrc ne '' ) {
			$caticon = qq|<img src="$caticonsrc" alt="" style="height:1em; width:auto; vertical-align:middle;">|;
		}

		push( @ret, '<tr><td>' . $ltag1 . $catid . $ltag2 . '</td><td>' . $catname . '</td><td>' . $caticon . '</td><td>' . $catdscrpt . '</td><td>' . $parentcat . '</td><td class="catposts">' . $catposts . '</td><td class="catorder">' . $catorder . '</td></tr>' );
	}

	if( $#ret == 0 ) {
		# 1件もなければ
		push( @ret, '<tr><td colspan="7">カテゴリが1つもありません。</td></tr>');
	}

	push( @ret, '</table>' );

	return @ret;
}

# -------------------------------
# ◆CAT：カテゴリIDから情報を得る	引数1：カテゴリID、引数2：得たい情報番号(1=表示名,2=概要文,3=親カテゴリID,4=該当個数,5=掲載順序,6=アイコンURL)
# -------------------------------	返値：得たいデータ（該当なしの場合は「空文字列」を返す）
sub getCategoryDetail
{
	my $searchid = shift @_ || '';
	my $detailno = shift @_ || 0;

	if( !$searchid ) { &errormsg('getCategoryDetail：カテゴリIDの指定がない'); }
	if( $detailno < 1 || $detailno > 6 ) { &errormsg('getCategoryDetail：得たい情報番号が不正'); }		# 値が1～6の範囲外ならエラー

	for my $i ( 0 .. $#catdata ) {
		if( $catdata[$i][0] eq $searchid ) {
			return $catdata[$i][$detailno];
		}
	}

	return '';
}

# -----------------------------------
# ◆CAT：カテゴリの最終順序番号を得る	返値：(0以上で)最も大きい順序番号
# -----------------------------------
sub getCategoryLastOrder
{
	my $max = 0;

	# 全ユーザをループ
	for my $i ( 0 .. $#catdata ) {
		if( $max < $catdata[$i][5] ) {
			$max = $catdata[$i][5];
		}
	}

	return $max;
}

# -----------------------------		引数：[0]=返値は「カテゴリID」の配列
# ◆CAT：カテゴリIDリストを得る		引数：[1]=返値は「カテゴリID<>カテゴリ名」の配列
# -----------------------------		引数：[2]=返値は「カテゴリID<>カテゴリ名<>該当数」の配列
sub getCategoryList
{
	my $type = shift @_ || 0;
	my @ret;

	# 全カテゴリをループ
	for my $i ( 0 .. $#catdata ) {
		if( $type == 1 ) {
			push( @ret, "$catdata[$i][0]<>$catdata[$i][1]" );
		}
		elsif( $type == 2 ) {
			push( @ret, "$catdata[$i][0]<>$catdata[$i][1]<>$catdata[$i][4]" );
		}
		else {
			push( @ret, "$catdata[$i][0]" );
		}
	}

	return @ret;
}

# -------------------------------------------------
# ◆CAT：カテゴリIDリストをselect＋option要素で得る		引数1：select要素に加えるname属性値、引数2：先頭に空白項目を(1:入れる/0:入れない)、引数3：初期選択するID名、引数4：除外するID名
# -------------------------------------------------		返値：HTMLソース（※カテゴリが1つもなければ空文字）
sub getCategorySelectList
{
	my $nameattr = shift @_ || 'tryid';
	my $addblank = shift @_ || 0;
	my $defcatid = shift @_ || '';
	my $outcatid = shift @_ || '';

	my @catlist = &getCategoryList(1);
	my $html = '';

	# カテゴリが1つ以上ある場合にだけ、HTMLソースを生成する
	if( $#catlist >= 0 ) {
		$html = '<select name="' . $nameattr . '">';
		if( $addblank == 1 ) {
			# 先頭にブランク項目を入れる
			$html .= qq|<option value="" class="blankitem">なし</option>|;
		}
		foreach my $cl (@catlist) {
			# IDと名称に分割
			my @ci = split(/<>/,$cl);
			# デフォルトチェック判定
			my $checked = '';
			if( $defcatid eq $ci[0] ) {
				$checked = ' selected';
			}
			# HTML化
			if( $outcatid ne $ci[0] ) {
				# 除外対象でなければHTMLを追加
				$html .= qq|<option value="$ci[0]"$checked>$ci[1] ($ci[0])</option>|;
			}
		}
		$html .= '</select>';
	}

	return $html;
}


# 														=== ▼ファイル読み書き ===

# -------------------- #
# ◆XML：XMLの読み込み #	引数： XMLファイル名, 抽出要素名
# -------------------- #	返値： XML中身の配列（1要素1レコード）
sub XMLin
{
	my $filename = shift @_;
	my $element  = shift @_;
	my @data;

	&safetyfilename($filename,1);	# 不正ファイル名の確認
	open(XML, $filename) or &errormsg("データファイルが開けませんでした：" . &forsafety($filename) );
	flock(XML, 1);
	foreach my $onerec (<XML>) {
		if( $onerec =~ m|<$element>.*</$element>| ) {
			# 指定要素名のあるレコードがあれば抽出
			push( @data, $onerec );
		}
	}
	close XML;

	return @data;
}

# -------------------- #
# ◆XML：XMLの並べ替え #	引数： XMLファイル名, 対象データの要素名、整列順序(0=降順/1=昇順)
# -------------------- #	返値： 1=出力成功, 0=出力失敗
sub XMLsort
{
	my $filename = shift @_ || 'nofilename';
	my $element  = shift @_ || 'noelement';
	my $order	 = shift @_ || 0;

	my @before = ();
	my @data = ();
	my @after = ();
	my $dataexistflag = 0;

	&safetyfilename($filename,1);	# 不正ファイル名の確認
	open(XML, $filename) or &errormsg("データファイルが開けませんでした：" . &forsafety($filename) );
	flock(XML, 1);
	foreach my $onerec (<XML>) {

		if( $onerec =~ m|<$element>.*</$element>| ) {
			# 指定要素名のあるレコードがあればdata配列に格納
			push( @data, $onerec );
			# フラグを立てる
			$dataexistflag = 1;
		}
		else {
			# 指定要素名のない行なら
			if( $dataexistflag == 0 ) {
				# まだデータが現れていないならbeforeに格納
				push( @before, $onerec );
			}
			else {
				# もうデータが現れているならafterに格納
				push( @after, $onerec );
			}
		}

	}
	close XML;

	# 配列@dataの中身をソート
	if( $order == 0 ) {
		# ソート(辞書順で降順)
		@data = sort { $b cmp $a } @data;
	}
	else {
		# ソート(辞書順で昇順)
		@data = sort { $a cmp $b } @data;
	}

	# ファイル出力 (※ファイルが存在しない場合に +< だとエラーになる環境があるため)
	my $ret = 0;
	if( -f $filename ) {
		# ファイルがある場合
		if( open(OUT, "+< $filename") ) {
			flock(OUT, 2);				# ロック
			seek(OUT, 0, 0);			# ファイルポインタを先頭にセット
			print OUT @before;		# 書き込む1
			print OUT @data;		# 書き込む2
			print OUT @after;		# 書き込む3
			truncate(OUT, tell(OUT));	# ファイルサイズを書き込んだサイズにする
			close OUT;					# closeすれば自動でロック解除
			$ret = 1;
		}
	}
	else {
		# ファイルがない場合
		&errormsg("読み込んだはずのデータファイルが存在しなくなっています：" . &forsafety($filename) );
	}

	return $ret;
}

# -------------------- #
# ◆XML：XML内の再採番 #	引数： XMLファイル名, 対象データの要素名、再採番する要素名
# -------------------- #	返値： 1=出力成功, 0=出力失敗
sub XMLrenumbering
{
	my $filename = shift @_ || 'nofilename';
	my $element  = shift @_ || 'noelement';
	my $rntarget = shift @_ || 'noelement';

	my @before = ();
	my @data = ();
	my @after = ();
	my $dataexistflag = 0;

	&safetyfilename($filename,1);	# 不正ファイル名の確認
	open(XML, $filename) or &errormsg("データファイルが開けませんでした：" . &forsafety($filename) );
	flock(XML, 1);
	foreach my $onerec (<XML>) {

		if( $onerec =~ m|<$element>.*</$element>| ) {
			# 指定要素名のあるレコードがあればdata配列に格納
			push( @data, $onerec );
			# フラグを立てる
			$dataexistflag = 1;
		}
		else {
			# 指定要素名のない行なら
			if( $dataexistflag == 0 ) {
				# まだデータが現れていないならbeforeに格納
				push( @before, $onerec );
			}
			else {
				# もうデータが現れているならafterに格納
				push( @after, $onerec );
			}
		}

	}
	close XML;

	# 配列の個数を得る
	my $total = $#data + 1;

	# 配列内の番号記録要素を、連番で上書きする
	my $counter = $total;
	foreach my $one ( @data ) {
		$one =~ s|<$rntarget>.*?</$rntarget>|<$rntarget>$counter</$rntarget>|;
		$counter--;
	}

	# ファイル出力 (※ファイルが存在しない場合に +< だとエラーになる環境があるため)
	my $ret = 0;
	if( -f $filename ) {
		# ファイルがある場合
		if( open(OUT, "+< $filename") ) {
			flock(OUT, 2);				# ロック
			seek(OUT, 0, 0);			# ファイルポインタを先頭にセット
			print OUT @before;		# 書き込む1
			print OUT @data;		# 書き込む2
			print OUT @after;		# 書き込む3
			truncate(OUT, tell(OUT));	# ファイルサイズを書き込んだサイズにする
			close OUT;					# closeすれば自動でロック解除
			$ret = 1;
		}
	}
	else {
		# ファイルがない場合
		&errormsg("読み込んだはずのデータファイルが存在しなくなっています：" . &forsafety($filename) );
	}

	return $ret;

}

# -------------------- #
# ◆XML：XMLの書き出し #	引数： XMLファイル名, カバー要素名, 文字コード, 中身配列
# -------------------- #	返値： 1=出力成功, 0=出力失敗
sub XMLout
{
	my $filename = shift @_ || 'nofilename';
	my $coverelement = shift @_ || 'noelement';
	my $charcode = shift @_ || '';
	my @outputXML = @_;

	# 余計な空白と改行を取り除く
	# ＆整形のためにタブを挿入
	foreach my $onerec ( @outputXML ) {
		$onerec =~ s|^\s*(.+)\n*$|$1|;
		$onerec = "	$onerec\n";
	}

	# ヘッダと最上階層要素を追加
	unshift( @outputXML, "<$coverelement>\n" );
	unshift( @outputXML, qq(<?xml version="1.0" encoding="$charcode" ?>\n) );
	push( @outputXML, "</$coverelement>\n" );

	# ファイル出力 (※ファイルが存在しない場合に +< だとエラーになる環境があるため)
	my $ret = 0;
	&safetyfilename($filename,1);	# 不正ファイル名の確認
	if( -f $filename ) {
		# ファイルがある場合
		if( open(OUT, "+< $filename") ) {
			flock(OUT, 2);				# ロック
			seek(OUT, 0, 0);			# ファイルポインタを先頭にセット
			print OUT @outputXML;		# 書き込む
			truncate(OUT, tell(OUT));	# ファイルサイズを書き込んだサイズにする
			close OUT;					# closeすれば自動でロック解除
			$ret = 1;
		}
	}
	else {
		# ファイルがない場合
		if( open(OUT, "> $filename") ) {
			flock(OUT, 2);			# ロック
			print OUT @outputXML;	# 書き込む
			close OUT;				# closeすれば自動でロック解除
			$ret = 1;
		}
	}
	return $ret;
}

# --------------------- #
# ◆XML：内容の抜き出し #	引数： 元文字列, 抽出要素名
# --------------------- #	返値： 要素内部の文字列
sub getcontent
{
	my $xmlstring = shift @_ || '';
	my $element   = shift @_ || '';

	if( $xmlstring =~ m|<$element>(.*?)</$element>| ) {		# 最小一致
		return $1;
	}
	return '';
}

# --------------------- #
# ◆XML：レコードの作成 #	引数： レコード要素名, 中身の要素(配列)
# --------------------- #	返値： レコード文字列
sub makerecord
{
	my $recelement = shift @_;
	my $ret = "<$recelement>";

	foreach my $one (@_) {
		$ret .= $one;
	}
	$ret .= "</$recelement>";

	return $ret;
}

# ----------------- #
# ◆XML：要素の作成 #	引数： 要素名, 中身
# ----------------- #	返値： 要素文字列
sub makeelement
{
	my $elementname	= shift @_ || '';
	my $content		= shift @_ || '';

	$content =~ s|\r\n|<br />|g;	# 改行(CRLF)をタグに
	$content =~ s|\n|<br />|g;		# 改行(CR)をタグに
	$content =~ s|\r|<br />|g;		# 改行(LF)をタグに

	return qq|<$elementname>$content</$elementname>|;
}

# ------------------------ #
# ◆FIL：汎用INIの読み込み #	引数： INIファイル名
# ------------------------ #	返値： INI中身の連想配列（ini書式に該当しない行は除外）
sub INIin
{
	my $filename = shift @_;
	my %inidat;

	&safetyfilename($filename,1);	# 不正ファイル名の確認
	open(INI, $filename) or &errormsg("データファイルが開けませんでした：" . &forsafety($filename) );
	flock(INI, 1);
	foreach my $onerec (<INI>) {
		if( $onerec =~ m/^(.+?)=(.*)$/ ) { $inidat{$1} = $2; }	# 記録されている項目名(=の左側)に該当する連想配列(%inidat)に、各値(=の右側)を代入する。
	}
	close INI;

	return %inidat;
}
my @auli = (60,97,32,104,114,101,102,61,34,104,116,116,112,115,58,47,47,119,119,119,46,110,105,115,104,105,115,104,105,46,99,111,109,47,34,62);

# ----------------------------- #
# ◆FIL：汎用ファイルの読み込み #	引数1：ファイル名、引数2：読めなかった場合の動作(0:空文字を返す、1:エラー文字列を返す、2:エラーを表示して終わる)
# ----------------------------- #	返値： ファイルの中身 or エラー文字列
sub FILEin
{
	my $filename = shift @_;
	my $ifcantread = shift @_;
	my $ret = '';

	&safetyfilename($filename,1);	# 不正ファイル名の確認
	if( open(INF, $filename) ) {
		# 読めたら
		flock(INF, 1);
		$ret = join("",<INF>);
		close INF;
	}
	else {
		# 読めなかったら
		if( $ifcantread == 0 ) {	return '';	}
		elsif( $ifcantread == 1 ) {	return 'ERROR:ファイルが読めませんでした。';	}
		else { &errormsg("ファイルが開けませんでした：" . &forsafety($filename) );	}
	}

	return $ret;
}

# ----------------------------- #
# ◆FIL：汎用ファイルの書き出し #	引数： ファイル名, 中身配列
# ----------------------------- #	返値： 1=出力成功, 0=出力失敗
sub FILEout
{
	my $filename = shift @_ || 'nofilename';
	my @outputFILE = @_;

	# ファイル出力 (※ファイルが存在しない場合に +< だとエラーになる環境があるため)
	my $ret = 0;
	&safetyfilename($filename,1);	# 不正ファイル名の確認
	if( -f $filename ) {
		# ファイルがある場合
		if( open(OUT, "+< $filename") ) {
			flock(OUT, 2);				# ロック
			seek(OUT, 0, 0);			# ファイルポインタを先頭にセット
			print OUT @outputFILE;		# 書き込む
			truncate(OUT, tell(OUT));	# ファイルサイズを書き込んだサイズにする
			close OUT;					# closeすれば自動でロック解除
			$ret = 1;
		}
	}
	else {
		# ファイルがない場合
		if( open(OUT, "> $filename") ) {
			flock(OUT, 2);			# ロック
			print OUT @outputFILE;	# 書き込む
			close OUT;				# closeすれば自動でロック解除
			$ret = 1;
		}
	}
	return $ret;
}

# --------------------------------------------------- #
# ◆FIL：ファイル名として成立する文字列かどうかを判定 #		引数: ファイル名
# --------------------------------------------------- #		返値: 1:成立する、0:成立しない
sub isvalidfilename
{
	my $filename = shift @_ || '';

	if( &safetyfilename($filename,2) eq '-' ) {
		# 使えない記号が含まれていればNG
		return 0;
	}

	if( $filename =~ /[a-zA-Z0-9_-]$/ ) {
		# 終わりの1文字が英数か_か-ならOK
		return 1;
	}

	return 0;
}

# 														=== ▼暦 ===

# ---------------------------
# ◆CAL：箱形カレンダーを生成	引数1～7：(下記の通り)
# ---------------------------	返値：カレンダー表示HTML
sub makecalendarbox
{
	my $year  = shift @_ || 0;			# 引数1：年
	my $month = shift @_ || 0;			# 引数2：月
	my $ref_daylinks = shift @_ || '';	# 引数3：リンク用配列へのリファレンス
	my $weekrow = shift @_ || '';		# 引数4：曜日セット (※中身は <日><月><火><水><木><金><土> の書式で各値は安全化済みの前提。)
	my $ref_linkclass = shift @_ || '';	# 引数5：class用配列へのリファレンス
	my $def_hdsigns = shift @_ || '';	# 引数6：祝日サイン配列へのリファレンス (祝日なら holiday、休日なら offday 等のサイン群の配列。)
	my $def_dayhtml = shift @_ || '';	# 引数7：1日枠の生HTML配列へのリファレンス (※ここに配列を渡す場合は、各日の内側はこの関数では生成しない。呼び出し元で完全なHTMLを出力していることが前提。)

	my @calbox = ();
	my $calhtml = '';

	# 現在の日付を取得
	my ($nowday,$nowmonth,$nowyear) = (localtime(time))[3,4,5];
	$nowyear  += 1900;
	$nowmonth += 1;

	# 年月指定があればそれを使う（なければ現在の年月を使う）
	if( $year  == 0 ) { $year = $nowyear; }
	if( $month == 0 ) { $month = $nowmonth; }

	# 指定年月の1日が何曜日かを調べる
	my $startyoubi = &getDayOfWeek($year,$month,1);

	# カレンダー先頭の空白を必要なだけ挿入する (※日曜日が1日なら0個、土曜日が1日なら6個)
	for( my $count = 0 ; $count < $startyoubi ; $count++ ) {
		push( @calbox, '' );
	}

	# 指定年月の最終日を得る
	my $lastday = &getLastDayOfMonth($year,$month);			# 最終日を得る

	# 1日から最終日まで配列に加える
	for( my $oneday = 1 ; $oneday <= $lastday ; $oneday++ ) {
		push( @calbox, $oneday );
	}

	# カレンダー末尾に空白を必要なだけ挿入する (※セル数が7の倍数になるまで加える)
	# 今の配列の個数が「 $#calbox+1 」で分かる。例えば31個なら、35までセルを用意する必要がある。31÷7 ＝ 4余り3 なので、あと必要なセル数は 7-3＝4個だと分かる。
	my $needaft = 7 - (($#calbox+1) % 7 );
	if( $needaft < 7 ) {
		# 必要な個数が7個未満の場合だけ加える
		for( my $count = 0 ; $count < $needaft ; $count++ ) {
			push( @calbox, '' );
		}
	}

	# 曜日行用のHTMLソースを作成
	if( $weekrow ne '' ) {
		# 曜日データがある場合のみ
		$weekrow =~ s|<(.+?)>|<th>$1</th>|g;
		$weekrow = '<thead><tr class="daysofweek">' . $weekrow . '</tr></thead>' . "\n";
	}

	# HTML化する
	my $col = 0;
	$calhtml = qq|\n<table class="calendar year$year month$month">\n<caption><span class="cyear">$year年</span><span class="cmonth">| . int($month) . qq|月</span></caption>\n|;
	$calhtml .= $weekrow . "<tbody>\n";
	foreach my $one ( @calbox ) {

		# ------
		# 週改行
		# ------
		my $befday = '';
		my $aftday = '';
		my $colret = $col % 7;
		if( $colret == 0 ) {
			# 余り0なら週の先頭曜日
			my $weekno = $col / 7 + 1;
			$befday = qq|<tr class="week$weekno">|;
		}
		elsif( $colret == 6 ) {
			# 余り6なら週の最終曜日
			$aftday = "</tr>\n";
		}
		$col++;

		# ----------------------
		# 日属性・日リンクの作成
		# ----------------------
		my $dayatt = '';		# 日属性
		my $insidebef = '';		# 日リンク(開)
		my $insideatf = '';		# 日リンク(閉)

		# 日の存在確認
		if( $one ne '' ) {
			# 日があれば
			$dayatt .= "day$one";

			# ……………………………
			# 曜日class文字列を挿入
			if( $colret == 0 ) {	$dayatt .= ' sun'; }
			elsif( $colret == 1 ) {	$dayatt .= ' mon'; }
			elsif( $colret == 2 ) {	$dayatt .= ' tue'; }
			elsif( $colret == 3 ) {	$dayatt .= ' wed'; }
			elsif( $colret == 4 ) {	$dayatt .= ' thu'; }
			elsif( $colret == 5 ) {	$dayatt .= ' fri'; }
			elsif( $colret == 6 ) {	$dayatt .= ' sat'; }

			# ………………………
			# 今日かどうかを確認
			# ………………………
			if( ($one == $nowday) && ($month == $nowmonth) && ($year == $nowyear) ) {
				# 今日なら
				$dayatt .= ' today';
			}

			# ………………………………
			# 祝日サインがあれば加える
			# ………………………………
			if( $def_hdsigns ) {
				# 祝日サイン群用の配列がある場合だけ実行
				if( @$def_hdsigns[$one] ne '' ) {
					# 中身があれば加える
					$dayatt .= ' ' . @$def_hdsigns[$one];
				}
			}

			# …………………
			# 日リンクを作成	※生HTML配列が指定されていればそちらを使う。指定されていなければここで生成する。
			# …………………
			if( $def_dayhtml ) {
				# 生HTML配列をそのまま出力する
				if( @$def_dayhtml[$one] ne '' ) {
					# 中身があればそのまま使う
					$one = @$def_dayhtml[$one];
				}
				else {
					# 中身がなければコメントだけ
					$one = "<!-- Blank $one -->";
				}
			}
			else {
				# ここで生成する
				if(( $ref_daylinks ) && ( @$ref_daylinks[$one] ne '' )) {
					# リンク用文字列があれば使う
					my $classstring = '';
					if(( $ref_linkclass ) && ( @$ref_linkclass[$one] ne '' )) {
						# class用文字列があれば使う
						$classstring = @$ref_linkclass[$one];
					}
					$insidebef = qq|<a href="@$ref_daylinks[$one]" class="$classstring">|;
					$insideatf = '</a>';
				}
				else {
					# リンクにならない日付用
					$insidebef = '<span class="nolink">';
					$insideatf = '</span>';
				}
			}
		}
		else {
			# 日がなければ
			$dayatt .= "empty";
		}

		# 日出力
		$calhtml .= qq|$befday<td class="$dayatt">$insidebef$one$insideatf</td>$aftday|;
	}
	$calhtml .= "</tbody></table>\n";

	return $calhtml;
}

# ---------------------------------
# ◆CAL：振替休日と国民の休日を計算	引数1～3：(下記の通り)
# ---------------------------------	返値：YYYY/MM/DD形式のリスト(指定月に存在する振替休日)
sub getSubstituteHolidays
{
	my $year  = shift @_ || &errormsg('No Year on getSubstituteHolidays');		# 引数1：年
	my $month = shift @_ || &errormsg('No Month on getSubstituteHolidays');		# 引数2：月
	my $def_hdsigns = shift @_ || &errormsg('No List on getSubstituteHolidays');	# 引数3：祝日サイン配列へのリファレンス (祝日なら holiday、休日なら offday 等のサイン群の配列。)

	my @calbox = ();
	my @subholidays = ();

	# 指定年月の1日が何曜日かを調べる
	my $startyoubi = &getDayOfWeek($year,$month,1);

	# カレンダー先頭の空白を必要なだけ挿入する (※日曜日が1日なら0個、土曜日が1日なら6個)
	for( my $count = 0 ; $count < $startyoubi ; $count++ ) {
		push( @calbox, '' );
	}

	# 指定年月の最終日を得る
	my $lastday = &getLastDayOfMonth($year,$month);			# 最終日を得る

	# 1日から最終日まで配列に加える
	for( my $oneday = 1 ; $oneday <= $lastday ; $oneday++ ) {
		push( @calbox, $oneday );
	}

	# カレンダー末尾に空白を必要なだけ挿入する (※セル数が7の倍数になるまで加える)
	# 今の配列の個数が「 $#calbox+1 」で分かる。例えば31個なら、35までセルを用意する必要がある。31÷7 ＝ 4余り3 なので、あと必要なセル数は 7-3＝4個だと分かる。
	my $needaft = 7 - (($#calbox+1) % 7 );
	if( $needaft < 7 ) {
		# 必要な個数が7個未満の場合だけ加える
		for( my $count = 0 ; $count < $needaft ; $count++ ) {
			push( @calbox, '' );
		}
	}

	# 振替休日判定用の作業変数
	my $furikaeflag = 0;	# 次の平日を振替休日にするフラグ

	# HTML化する
	my $col = 0;
	foreach my $one ( @calbox ) {

		# 曜日確認
		my $colret = $col % 7;		# 変数$colretの値が0なら日曜日、6なら土曜日。
		$col++;

		# 日の存在確認
		if( $one ne '' ) {
			# 日があれば

			# ………………
			# 振替休日判定
			# ………………
			if(( $colret == 0 ) && ( @$def_hdsigns[$one] =~ /holiday/ )) {
				# 日曜日でかつ祝日指定があれば、振替休日フラグを立てる（＝次の平日が振替休日）
				$furikaeflag = 1;
			}
			elsif(( $furikaeflag == 1 ) && ( $colret > 0 ) && ( @$def_hdsigns[$one] !~ /holiday/ )) {
				# 振替休日フラグが立っていて、月～土で、かつ祝日指定がなければ、そこが振替休日
				push( @subholidays, ("$year/" . &addzero($month) . '/' . &addzero($one) . ',振替休日' ));
				$furikaeflag = 0;	# フラグを下ろす
			}

			# …………………
			# 国民の休日判定
			# …………………
			if(( $colret != 0 ) && ( @$def_hdsigns[$one] !~ /holiday/ ) && ( $one > 1 )) {
				# 今日が日曜日でも祝日でもなく、1日以降の場合にだけ判定（＝元々祝日である日や日曜日は国民の休日にならない仕様、1ヶ月単位で出力する仕様なので前月末日と今月2日との間が国民の休日になる可能性は考慮できない）
				if(( @$def_hdsigns[$one-1] =~ /holiday/ ) && ( @$def_hdsigns[$one+1] =~ /holiday/ )) {
					# 前日が祝日で翌日も祝日なら、今日は国民の休日
					push( @subholidays, ("$year/" . &addzero($month) . '/' . &addzero($one) . ',国民の休日' ));
				}
			}

		}
	}

	return @subholidays;
}

# -------------------
# ◆CAL：閏年チェック　引数：西暦年、戻り値： 0=閏年でない／1=閏年である
# -------------------
sub checkleapyear
{
	my $year = shift @_ || 2020;

	if( $year % 400 == 0 ) { return 1; }	# 400で割り切れたら閏年
	if( $year % 100 == 0 ) { return 0; }	# 100で割り切れたら閏年ではない
	if( $year %   4 == 0 ) { return 1; }	# 4で割り切れたら閏年

	return 0;	# それ以外は閏年でない
}

# -------------------------
# ◆CAL：指定日の曜日を得る	引数1～3：年,月,日
# -------------------------	返値：曜日(0=日曜日,1=月曜日～6=土曜日／-1:日付が存在しない
sub getDayOfWeek
{
	my $year  = shift @_ || 2020;	# 年
	my $month = shift @_ || 1;		# 月
	my $day   = shift @_ || 1;		# 日
	my $wday = -1;

	# 指定年月の1日のEPOC秒を得る
	my $epoc = eval{ &Time::Local::timelocal(0,0,0,$day, $month-1, $year) };
	if( defined( $epoc ) ) {
		# epocが定義されていれば、正しい日付なので曜日を得る
		$wday = (localtime($epoc))[6];
	}

	return $wday;
}

# ---------------------------
# ◆CAL：指定月の最終日を得る	引数1：年、引数2：月、返値：日(28～31)
# ---------------------------
sub getLastDayOfMonth
{
	my $year  = shift @_ || 2020;	# 年
	my $month = shift @_ || 1;		# 月

	# 各月の最終日リスト
	my @lastdaylist = ( undef, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

	# 閏年なら2月を修正
	if( &checkleapyear($year) == 1 ) {
		$lastdaylist[2] = 29;
	}

	return $lastdaylist[$month];
}

# -------------------------------------------------------
# ◆CAL：春分の日・夏至・秋分の日・冬至が何日なのかを計算	引数1：西暦(数値)、引数2：月(数値)、返値：日
# -------------------------------------------------------
sub getVAEquinoxDay
{
	my $year  = shift @_ || 2020;	# 年
	my $month = shift @_ || 1;		# 月
	my $ret = -1;	# 戻り値(日)

	if(    $month == 3 ) { $ret = int( 20.8431 + 0.242194 * ( $year - 1980 ) - int( ( $year - 1980 ) / 4 ) ); }	# 春分の日 Vernal Equinox Day
	elsif( $month == 9 ) { $ret = int( 23.2488 + 0.242194 * ( $year - 1980 ) - int( ( $year - 1980 ) / 4 ) ); }	# 秋分の日 Autumn Equinox Day

	elsif( $month == 6 ) { $ret = int( 22.2747 + 0.24162603 * ( $year - 1900 ) - int( ( $year - 1900 ) / 4 ) ); }	# 夏至 Summer Solstice	※2099年まで有効な計算式
	elsif( $month == 12) { $ret = int( 22.6587 + 0.24274049 * ( $year - 1900 ) - int( ( $year - 1900 ) / 4 ) ); }	# 夏至 Winter Solstice

	elsif( $month == 2 ) { $ret = int( 4.8693 + 0.242713 * ( $year - 1901 ) - int( ( $year - 1901 ) / 4 ) ) - 1; }	# 節分

	return $ret;
}

# --------------------
# ◆CAL：第n曜日の判定		引数1：その月の1日の曜日(日0～土6)、引数2：第何週(数値:n)、引数3：曜日(日0～土6:w)、返値：(指定月の第n・w曜日の)日
# --------------------
sub getDayNthWeek
{
	my $week1st   = shift @_ || 0;	# その月の1日の曜日(日0～土6)
	my $wantweek  = shift @_ || 0;	# 第何週？(n:1～5)
	my $wantyoubi = shift @_ || 0;	# 何曜日？(日0～土6)

	# 月曜日群リスト(計算で求まりそうだが)
	my $weekdays = [
		[2,9,16,23,30],  # 1日が日曜日の場合の第n月曜日リスト
		[1,8,15,22,29],  # 1日が月曜日の場合の第n月曜日リスト
		[7,14,21,28,0],  # 1日が火曜日の場合の第n月曜日リスト(第5週はない)
		[6,13,20,27,0],  # 1日が水曜日の場合の第n月曜日リスト(第5週はない)
		[5,12,19,26,0],  # 1日が木曜日の場合の第n月曜日リスト(第5週はない)
		[4,11,18,25,0],  # 1日が金曜日の場合の第n月曜日リスト(第5週はない)
		[3,10,17,24,31]  # 1日が土曜日の場合の第n月曜日リスト
	];

	# 欲しい日が月曜日ではない場合の処理
	my $shiftstep = 0;
	if(    $wantyoubi == 0 ) { $shiftstep = 1; } # 第n日曜日を得たい場合
	elsif( $wantyoubi == 2 ) { $shiftstep = 6; } # 第n火曜日を得たい場合
	elsif( $wantyoubi == 3 ) { $shiftstep = 5; } # 第n水曜日を得たい場合
	elsif( $wantyoubi == 4 ) { $shiftstep = 4; } # 第n木曜日を得たい場合
	elsif( $wantyoubi == 5 ) { $shiftstep = 3; } # 第n金曜日を得たい場合
	elsif( $wantyoubi == 6 ) { $shiftstep = 2; } # 第n土曜日を得たい場合

	# 第1添え字(1次元目)を計算
	my $selectline = $week1st + $shiftstep;
	if( $selectline > 6 ) { $selectline -= 7; }		# 日付リストは0～6の7種なので、ずらした結果7以上になるなら7を引いて0～6の範囲に収める。

	return $weekdays->[$selectline][$wantweek-1];
}

# --------------------------
# ◆CAL：nヶ月後の年月を得る	引数1：年、引数2：月、引数3：何ヶ月後の年月が必要？(数値)
# --------------------------	返値：(年,月)の配列
sub getnMonthLater
{
	my $baseyear   = shift @_ || (localtime(time))[5] + 1900;	# 年 (無指定なら現在年)
	my $basemonth  = shift @_ || (localtime(time))[4] + 1;		# 月 (無指定なら現在月)
	my $plusmonths = shift @_ || 0;		# 加える月数

	my $retyear = $baseyear;
	my $retmonth = $basemonth + $plusmonths;	# 月に指定月数を加えてみる

	# 月が1～12の範囲外だったら年数との調整処理
	while( $retmonth > 12 || $retmonth < 1 ) {
		if( $retmonth > 12 ) {
			# 月が12を超えていたら、月から12を引いて、年に1を足す。
			$retmonth -= 12;
			$retyear++;
		}
		elsif( $retmonth < 1 ) {
			# 月が1を下回っていたら、月に12を足して、年から1を引く。
			$retmonth += 12;
			$retyear--;
		}
	}

	return ($retyear, $retmonth);
}

# -----------------------------
# ◆CAL：元号付きの和暦年を得る		引数1：西暦(年)、引数2：月、引数3：日
# -----------------------------		返値：(元号,年数)の配列
sub getImperialEraYear
{
	my $year	= shift @_ || (localtime(time))[5] + 1900;	# 年 (無指定なら現在年)
	my $month	= shift @_ || (localtime(time))[4] + 1;		# 月 (無指定なら現在月)
	my $day		= shift @_ || (localtime(time))[3];			# 日 (無指定なら現在日)

	my $gengo = '';
	my $nen = 0;

	if(( $year > 2019 ) || ( $year == 2019 && $month >= 5 )) {
		# 令和：2019年5月以降
		$gengo = '令和';
		$nen = $year - 2018;
	}
	elsif(( $year > 1989 ) || ( $year == 1989 && $month > 1 ) || ( $year == 1989 && $month == 1 && $day >= 8 )) {
		# 平成：1989年1月8日以降
		$gengo = '平成';
		$nen = $year - 1988;
	}
	elsif(( $year > 1926 ) || ( $year == 1926 && $month == 12 && $day >= 25 )) {
		# 昭和：1926年12月25日以降
		$gengo = '昭和';
		$nen = $year - 1925;
	}
	else {
		# 大正以前は非対応として、元号なし＋西暦そのままを返す
		$gengo = '';
		$nen = $year;
	}

	return ($gengo , $nen);
}


# 														=== ▼日付汎用 ===

# ---------------------------	引数なし
# ◆DAY：現在日時を配列で返す	返値：配列：[0]=年,[1]=月,[2]=日,[3]=曜(0～6),[4]=時,[5]=分,[6]=秒,[7]=今年何日目(1～366),[8]=夏時間(1/0)
# ---------------------------	使用例：「年月日だけが欲しい場合」(&fcts::getnowdate())[0,1,2]
sub getnowdate
{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900;
	$mon  += 1;
	$yday += 1;

	return ($year,$mon,$mday,$wday,$hour,$min,$sec,$yday,$isdst);
}

# ---------------------------------
# ◆DAY：整形された日時文字列を返す	引数1がなければ現在時刻、あればそれを使う
# ---------------------------------	引数2：0=年月日時分秒、1=年月日
sub getdatetimestring
{
	my $reqtime = shift @_ || time;
	my $kind = shift @_ || 0;

	# 現在時刻を取得
	my ($sec,$min,$hour,$mday,$month,$year) = (localtime($reqtime))[0,1,2,3,4,5];
	$year  = $year + 1900;
	$month = $month + 1;

	$sec   = &fcts::addzero($sec  );
	$min   = &fcts::addzero($min  );
	$hour  = &fcts::addzero($hour );
	$mday  = &fcts::addzero($mday );
	$month = &fcts::addzero($month);

	if( $kind == 1 ) {
		return "$year/$month/$mday";
	}
	return "$year/$month/$mday $hour:$min:$sec";
}

# -------------------------------------
# ◆DAY：ファイル名に使う用の日付を返す	引数1：〔なし(0)=年月日のみ、1=年月日時分秒〕、引数2：対象時刻
# -------------------------------------
sub getNowDateForFileName
{
	my $parts = shift @_ || 0;
	my $targettime = shift @_ || time;	# 省略すると今の日時

	my ($sec,$min,$hour,$mday,$month,$year) = (localtime($targettime))[0,1,2,3,4,5];
	$year  = $year + 1900;
	$month = &addzero($month + 1);
	$mday  = &addzero($mday);
	$hour  = &addzero($hour );
	$min   = &addzero($min  );
	$sec   = &addzero($sec  );

	if( $parts == 1 ) {
		return "$year$month$mday$hour$min$sec";		# 年月日時分秒を返す
	}
	return "$year$month$mday";	# 年月日のみを返す
}

# ---------------------------------
# ◆DAY：指定された日時の曜日を返す	引数1は形態、引数2は秒
# ---------------------------------
sub getweek
{
	my $kind = shift @_ || 0;
	my $esec = shift @_ || time;

	my @weekjps = ('日','月','火','水','木','金','土');
	my @weekjpf = ('日曜日','月曜日','火曜日','水曜日','木曜日','金曜日','土曜日');
	my @weekens = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
	my @weekenf = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');

	# 時刻から曜日を取得
	my $wday = (localtime($esec))[6];

	if( 	$kind == 0 ) { return $weekjps[$wday]; }
	elsif(	$kind == 1 ) { return $weekjpf[$wday]; }
	elsif(	$kind == 2 ) { return $weekens[$wday]; }
	elsif(	$kind == 3 ) { return $weekenf[$wday]; }
	else {
		return $weekjps[$wday];
	}
}

# -------------------------------
# ◆DAY：月を各言語名称表記に変更　引数1：月番号(1～12)、引数2：種類(0:和暦月名、1:英名省略形、2:英名フル)
# -------------------------------
sub getmonthname
{
	my $month = shift @_ || 0;
	my $mflag = shift @_ || 0;

	my @wareki = ('睦月','如月','弥生','卯月','皐月','水無月','文月','葉月','長月','神無月','霜月','師走');
	my @mengs = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
	my @mengf = ('January','February','March','April','May','June','July','August','September','October','November','December');

	# 月番号が1～12の範囲外の場合は「？」を返す
	if( $month > 12 || $month < 1 ) { return '？'; }

	$month--;
	if( 	$mflag == 0 ) { return $wareki[$month]; }
	elsif(	$mflag == 1 ) { return $mengs[$month]; }
	elsif(	$mflag == 2 ) { return $mengf[$month]; }
	else {
		return $mengs[$month];
	}
}

# ---------------------------
# ◆DAY：秒数を時間表記に整形　引数：秒数(数値)
# ---------------------------
sub sectotimestring
{
	my $second = shift @_;

	my $timeoutday  = int( $second / (60*60*24));
	my $timeouthour = int(($second % (60*60*24)) / (60*60));
	my $timeoutmin  = int(($second % (60*60)) / 60);
	my $timeoutsec  = $second % 60;

	my $ret = '';
	$ret .= "$timeoutday"."日" if( $timeoutday > 0 );
	$ret .= "$timeouthour"."時間" if( $timeouthour > 0 );
	$ret .= "$timeoutmin"."分" if( $timeoutmin > 0 );
	$ret .= "$timeoutsec"."秒" if( $timeoutsec > 0 );

	return $ret;
}

# -----------------------------
# ◆DAY：日付を日本語表記に整形　引数：日付文字列（YYYY/MM/DD hh:mm:ss 形式）
# -----------------------------
sub datetojpstyle
{
	my $datestr = "D" . shift @_;

	$datestr =~ s/^D(\d\d\d\d).(\d+).(\d+) (\d+):(\d+):(\d+).*/$1年$2月$3日 $4時$5分$6秒/g;
	$datestr =~ s/^D(\d\d\d\d).(\d+).(\d+) (\d+):(\d+).*/$1年$2月$3日 $4時$5分/g;
	$datestr =~ s/^D(\d\d\d\d).(\d+).(\d+) (\d+).*/$1年$2月$3日 $4時/g;
	$datestr =~ s/^D(\d\d\d\d).(\d+).(\d+).*/$1年$2月$3日/g;
	$datestr =~ s/^D(\d\d\d\d).(\d+).*/$1年$2月/g;
	$datestr =~ s/^D(\d\d\d\d).*/$1年/g;

	$datestr =~ s/^D(\d\d).(\d\d)$/全年$1月$2日/g;
	$datestr =~ s/^D(\d\d)$/全年全月$1日/g;

	return $datestr;	# 変換できなければ頭に「D」が付いた状態で返る
}
sub cutheadd
{
	my $trystr = shift @_;
	$trystr =~ s/^D(.+)/$1/;
	return $trystr;
}
sub cutzeroinjpdate
{
	my $dstr = shift @_ || '';

	# 日本語書式の日付から無用な0を消す
	$dstr =~ s/0(\d)(月|日)/$1$2/g;

	return $dstr;
}

# ---------------------------------		※Time::Localモジュールのtimelocalが使えることが前提
# ◆DAY：指定日時をエポック秒に戻す		引数1：日時文字列(YYYY/MM/DD hh:mm:ss)　※hh,mm,ssは省略可
# ---------------------------------		返値：エポック秒
sub getepochtime
{
	my $str = shift @_ || &errormsg('Datetime string Required.');

	my $year = 0;
	my $mon  = 0;
	my $day  = 0;
	my $hour = 0;
	my $min  = 0;
	my $sec  = 0;

	if( $str =~ m|^(\d\d\d\d)/(\d\d)/(\d\d)\s(\d\d):(\d\d):(\d\d)| ) 	{ $year = $1;	$mon = $2;	$day = $3;	$hour = $4;	$min = $5;	$sec  = $6;	}
	elsif( $str =~ m|^(\d\d\d\d)/(\d\d)/(\d\d)\s(\d\d):(\d\d)| )		{ $year = $1;	$mon = $2;	$day = $3;	$hour = $4;	$min = $5;	}
	elsif( $str =~ m|^(\d\d\d\d)/(\d\d)/(\d\d)\s(\d\d)| )				{ $year = $1;	$mon = $2;	$day = $3;	$hour = $4;	}
	elsif( $str =~ m|^(\d\d\d\d)/(\d\d)/(\d\d)| )						{ $year = $1;	$mon = $2;	$day = $3;	}
	else { &errormsg('YYYY/MM/DD Required.'); }

	# エポック秒に変換
	my $epoch = eval{ &Time::Local::timelocal($sec, $min, $hour, $day, $mon - 1, $year) };		# 注: timelocal では $year を -1900 しない！

	# epochが定義されていれば正しい日付なのでその秒を返す
	if( defined( $epoch ) ) {
		return $epoch;
	}

	# エポック秒に変換できなければ（与えられた日付が実在しないとか）0を返す
	return 0;
}

# --------------------------------
# ◆DAY：2つの日時文字列の差を得る		引数1と2：日時文字列(YYYY/MM/DD hh:mm:ss)　※hh,mm,ssは省略可
# --------------------------------		返値：差の秒数(引数両方が正しい日時だった場合)、'NA'(正しくない日時が与えられた場合)
sub comparedatestr
{
	my $date1 = shift @_ || &errormsg('Datetime 1 is required.');
	my $date2 = shift @_ || &errormsg('Datetime 2 is required.');

	# 指定日時をエポック秒に変換
	my $ep1 = &getepochtime( $date1 );
	my $ep2 = &getepochtime( $date2 );

	# どちらか一方でも正しくない日付なら'NA'を返す
	if( $ep1 == 0 || $ep2 == 0 ) {
		return 'NA';
	}

	# 正しい日付なら、エポック秒を引き算した値を返す
	return $ep1 - $ep2;
}

# ------------------------------------
# ◆DAY：2つの日時(UNIX時間)の差を得る		引数1と2：UNIX時間 (引数2を省略すれば現在日時)
# ------------------------------------		返値：差の秒数 (引数2が現在日時の場合は、プラスなら引数1は過去、マイナスなら引数1は未来)
sub comparedatetime
{
	my $date1 = shift @_ || 0;
	my $date2 = shift @_ || time;

	# エポック秒を引き算した値を返す
	return $date2 - $date1;
}

# ---------------------------------------------------
# ◆DAY：指定日時がどれくらい前なのかを単位付きで返す	引数1：対象日時のエポック秒、引数2：経過時間の表記に使われる単位「時間」の切り替え時間、引数3：「前」または「後」の文字を(1=加える/0=加えない)
# ---------------------------------------------------
sub howlongago
{
	my $tdate = shift @_ || 0;
	my $ctime = shift @_ || 0;
	my $addzg = shift @_ || 0;

	# 引数1がないか0の場合は正しい日付ではないと解釈
	if( $tdate == 0 ) {
		return '？';
	}

	# 引数2は24～2400の範囲のみ有効(範囲外は強制修正)
	if( $ctime < 24 ) { $ctime = 24; }
	if( $ctime > 2400 ) { $ctime = 2400; }
	# 値を秒に変換
	$ctime *= 3600;		# 1時間＝60分×60秒＝3600秒

	my $diff = time - $tdate;	# 現在日時との差を計算
	my $minus = 0;				# 未来フラグ
	if( $diff < 0 ) {
		# 指定日時が未来ならマイナスフラグを立てて、値自体は正にする
		$minus = 1;
		$diff *= -1;
	}

	my $res = 0;
	my $unit = '';
	if( $diff < 60 )			{ $res = $diff; $unit = '秒'; }						# 60秒未満なら秒を表示
	elsif( $diff < 3600 ) 		{ $res = int($diff / 60); $unit = '分'; }			# 60分未満なら分を表示(60*60=3600秒)
	elsif( $diff < $ctime )		{ $res = int($diff / 3600); $unit = '時間'; }		# 指定時間未満なら時間を表示 ※1日なら86400秒 2日なら172800秒(=60*60*48)
	elsif( $diff < 31557600 )	{ $res = int($diff / 86400); $unit = '日'; }		# 365.25日未満なら日を表示(60*60*24*365.25=31557600秒)
	else						{ $res = int($diff / 31557600); $unit = '年以上'; }	# それ以上なら年を表示

	# 前後を加えるかどうか
	if( $addzg == 1 ) {
		# 加える場合
		if( $minus == 0 ) { $unit .= '前'; }	# 過去は「××前」で表現
		else { $unit .= '後'; }					# 未来は「××後」で表現
	}
	else {
		# 加えない場合
		if( $minus == 1 ) { $res *= -1; }	# 未来は「-××」で表現
	}

	return "$res$unit";
}

# -------------------------------	※Time::Localモジュールのtimelocalが使えることが前提
# ◆DAY：時刻を指定時間だけずらす	引数：日時(YYYY/MM/DD hh:mm:ss), 表示時間(単位:時)
# -------------------------------	返値：ずらした時刻文字列(YYYY/MM/DD hh:mm:ss)
sub shifttime
{
	my $orgdate = shift @_ || '';
	my $shifthour = shift @_ || 0;

	my $shiftsec = $shifthour * 3600;

	# 投稿日時の形式が前提通りな場合だけ実行
	if( $orgdate =~ m|(\d\d\d\d)/(\d\d)/(\d\d) (\d\d):(\d\d):(\d\d)(.*)| ) {
		# 秒数に変換
		my $epoch = eval{ &Time::Local::timelocal($6, $5, $4, $3, $2 - 1, $1) };	# 注: timelocal では $year を -1900 しない！

		if( defined( $epoch ) ) {
			# epochが定義されていれば正しい日付なので処理を続行
			# 加減算
			$epoch += $shiftsec;
			# 整形し直して返す
			my $ret = &getdatetimestring($epoch);
			#&errormsg($orgdate . ' ' . $shiftsec . ' ' .$epoch . ' ' . $ret);
			return $ret;
		}
	}

	# 実行できなかったら引数をそのまま返す
	return $orgdate;
}

# ------------------------------- #	※Time::Localモジュールのtimelocalが使えることが前提
# ◆DAY：有効な日付かどうかの確認 #	引数：日付(YYYY/MM/DD)	※時刻はチェックしない
# ------------------------------- #	返値：有効なら1、無効なら0
sub datevalidation
{
	my $orgdate = shift @_ || '';
	if( $orgdate =~ m|(\d\d\d\d)\/(\d\d)\/(\d\d).*| ) {
		# 変数に分解
		my $year	= $1;
		my $month	= $2;
		my $day		= $3;

		# 有効かどうか
		my $epoc = eval{ &Time::Local::timelocal(0,0,0,$day, $month-1, $year) };

		if( defined( $epoc ) ) {
			# epocが定義されていれば、正しい日付
			return 1;
		}
	}

	# 正しくない日付の場合 (＋引数がおかしい場合は常にゼロを返す)
	return 0;
}


# 														=== ▼画像 ===

# --------------------------------
# ◆IMG：GIF画像の縦横サイズを得る	引数：ファイル名
# --------------------------------
sub extractWidthHeightGif
{
	my $file = shift @_	|| &errormsg('No GIF file name.');
	my ($w1,$w2,$h1,$h2);

	$file = &safetyfilename( $file ,1 );	# ファイル名の安全性確認

	open(GIF, "$file") || return(0,0);
    binmode GIF;
	seek(GIF, 6, 0);
	read(GIF, $w1, 1);
	read(GIF, $w2, 1);
	read(GIF, $h1, 1);
	read(GIF, $h2, 1);
	close(GIF);

	my $width = 0;
	my $height = 0;
	eval {
		my $w	= unpack("H*", $w2 . $w1);
		$width	= hex($w);

		my $h	= unpack("H*", $h2 . $h1);
		$height	= hex($h);
	};
	if($@) {
		# 正しく16進数が取得できなかった場合
		return(-1,-1);
	}

	return( $width, $height );
}

# --------------------------------
# ◆IMG：PNG画像の縦横サイズを得る	引数：ファイル名
# --------------------------------
sub extractWidthHeightPng
{
	my $file = shift @_	|| &errormsg('No PNG file name.');

	$file = &safetyfilename( $file ,1 );	# ファイル名の安全性確認

	open(PNG, "$file") || return(0,0);
	my $buf;
	my $width = 0;
	my $height = 0;
	binmode PNG;
	seek(PNG, 16,  0);
	read(PNG, $buf, 8);
	($width, $height) = unpack("NN", $buf);
	close(PNG);

	return( $width, $height );
}

# ---------------------------------
# ◆IMG：JPEG画像の縦横サイズを得る		引数：ファイル名
# ---------------------------------
sub extractWidthHeightJpeg
{
	my $file = shift @_	|| &errormsg('No JPEG file name.');

	$file = &safetyfilename( $file ,1 );	# ファイル名の安全性確認

	open(JPEG, "$file") || return(0,0);
	my $buf;
	my $width = 0;
	my $height = 0;
	binmode JPEG;
    seek(JPEG, 2, 0);
    my $loop = 256;	# ループ上限
    while($loop--){
		if( read(JPEG, $buf, 4) ) {
			# 読めたら
			my($mark, $c, $len) = unpack("H2 H2 n", $buf);
			last if($mark ne 'ff');

			if($c eq 'c0' || $c eq 'c2'){
				read(JPEG, $buf, 5);
				($height, $width) = unpack("x nn", $buf);
				last;
			}
			else{
				seek(JPEG, $len-2, 1);
			}
		}
		else {
			# 読めなかったら(＝ファイル終端 or エラー)
			last;
		}
    }
	close(JPEG);

	return( $width, $height );
}

# --------------------------------
# ◆IMG：SVG画像の縦横サイズを得る	引数：ファイル名
# --------------------------------
sub extractWidthHeightSvg
{
	my $file = shift @_	|| &errormsg('No SVG file name.');

	$file = &safetyfilename( $file ,1 );	# ファイル名の安全性確認

	open(SVG, "$file") || return(0,0);
	my $width = 0;
	my $height = 0;
	foreach my $svgline (<SVG>) {
		if( $svgline =~ m|<svg(.+?)>| ) {
			# svg要素を抽出
			my $svgtag = $1;
			if( $svgtag =~ m/height="(\d+)px"/ ) {
				# height
				$height = $1;
			}
			if( $svgtag =~ m/width="(\d+)px"/ ) {
				# width
				$width = $1;
			}
		}
	}
	close(SVG);

	return( $width, $height );
}

# -----------------------------
# ◆IMG：画像の縦横サイズを得る		引数：ファイル名
# -----------------------------		返値：(横幅,高さ)の配列
sub getImageWidthHeight
{
	my $file = shift @_	|| return(0,0);		# &errormsg('No image file name.');

	my $width = 0;
	my $height = 0;

	if( $file =~ m/.+\.png$/i ) {
		# PNG画像
		( $width, $height ) = &extractWidthHeightPng( $file );
	}
	elsif( $file =~ m/.+\.gif$/i ) {
		# GIF画像
		( $width, $height ) = &extractWidthHeightGif( $file );
	}
	elsif( $file =~ m/.+\.jpe?g$/i || $file =~ m/.+\.jpe$/i ) {
		# JPEG画像
		( $width, $height ) = &extractWidthHeightJpeg( $file );
	}
	elsif( $file =~ m/.+\.svg$/i ) {
		# SVG画像
		( $width, $height ) = &extractWidthHeightSvg( $file );
	}

	# 巨大すぎる場合はエラーとして-1を返す (JPEG形式なのに.png拡張子だと65536のような値が得られる)
	if(( $width > 10000 ) || ( $height > 10000 )) {
		return ( -1, -1 );
	}

	return ( $width, $height );
}


# 														=== ▼PATH ===

# ---------------------------------------------		引数1：URL1、引数2：URL2
# ◆PTH：2つのURLのドメインが同じかどうかを判断		返値：同じドメインなら1、異なるドメインなら0、どちらかのドメインが抽出できなければ-1
# ---------------------------------------------		※HTTP/HTTPS区別せず、//から書き始めても可。(少なくとも//は必要)
sub checkSameDomain
{
	my $urlA = shift @_	|| &errormsg('2 urls Required');
	my $urlB = shift @_	|| &errormsg('2 urls Required');

	my $domainA = '';
	my $domainB = '';

	# ドメイン部分を小文字に変換して抜き出し
	if( $urlA =~ m|^(?:https?:)?//([A-Za-z0-9.-]+?)/?| ) {	$domainA = lc $1;	}
	if( $urlB =~ m|^(?:https?:)?//([A-Za-z0-9.-]+?)/?| ) {	$domainB = lc $1;	}

	# どちらかのドメインが抽出できなかったら終了
	if( $domainA eq '' || $domainB eq '' ) {
		return -1;
	}

	# ドメインが同じかどうか判断
	if( $domainA eq $domainB ) {
		# 同じなら
		return 1;
	}
	else {
		# 違っていれば
		return 0;
	}
}

# ---------------------------------------------------------------------
# ◆PTH：URLからドメイン名までを除外して「/」で始まるフルパスの形にする		引数：URL　※HTTP/HTTPS区別せず、//から書き始めても可。(少なくとも//は必要)
# ---------------------------------------------------------------------		返値：「/」で始まるフルパス（無理なら空文字）
sub cutofftofullpath
{
	my $url = shift @_	|| '';

	if( $url =~ m|^(?:https?:)?//[A-Za-z0-9.-]+?(/.*)| ) {
		return $1;
	}

	return '';
}

# ---------------------------------------------------------------------
# ◆PTH：DOCUMENT ROOTと「/」で始まるフルパスを合わせてサーバパスを作る		引数1：DOCUMENT ROOT、引数2：「/」で始まる絶対パス
# ---------------------------------------------------------------------
sub combineforservpath
{
	my $docroot = shift @_	|| '';
	my $fullpath = shift @_	|| '';

	# DOCUMENT ROOTの末尾にスラッシュがあれば一旦消す
	$docroot =~ s|/$||;

	# フルパスの先頭にスラッシュがあれば一旦消す
	$fullpath =~ s|^/||;

	# 両方を繋げて返す
	return $docroot . '/' . $fullpath ;
}

# --------------------------------------
# ◆PTH：環境変数からDOCUMENT ROOTを得る
# --------------------------------------
sub envDocumentRoot
{
	my $ret = '';
	# DOCUMENT_ROOTから得る
	$ret = $ENV{DOCUMENT_ROOT} || '';
	if( $ret eq '' ) {
		# 代わりにCONTEXT_DOCUMENT_ROOTから得る
		$ret = $ENV{CONTEXT_DOCUMENT_ROOT} || '';
		if( $ret eq '' ) {
			# 代わりにSCRIPT_FILENAMEからSCRIPT_NAMEを引く
			my $sfn = $ENV{SCRIPT_FILENAME} || '';
			my $sn = $ENV{SCRIPT_NAME} || '';
			$sfn =~ s|$sn||;
			$ret = $sfn;
		}
	}
	return $ret;
}

# ---------------------------------------
# ◆PTH：サムネイル格納位置用のパスを返す	引数1：元のパス、引数2：サムネイル用ディレクトリ名
# ---------------------------------------
sub makethumbnailpath
{
	my $orgpath = shift @_	|| '';
	my $thumbdir = shift @_	|| '';

	my @dirs = split(/\//,$orgpath);		# スラッシュで分割

	if( $#dirs >= 0 ) {
		# スラッシュが1つ以上ある場合のみ処理
		my $filename = $dirs[$#dirs];		# 最後の要素(＝ファイル名)を保持しておく
		$dirs[$#dirs] = $thumbdir;			# そこにサムネイル用ディレクトリ名を入れる
		$dirs[$#dirs+1] = $filename;		# ファイル名を最後に戻す
		my $ret = join('/', @dirs);

		return $ret;
	}

	# スラッシュがなければ元のパスをそのまま返す
	return $orgpath;
}

# ---------------------------------------------------
# ◆PTH：ベースURLと付加パスを合体させて絶対URLを作る	引数1：ベースURL、引数2：付加パス
# ---------------------------------------------------
sub makefullurl
{
	my $baseurl = shift @_	|| '';
	my $addpath = shift @_	|| '';

	# ベースURLの末尾を必ずスラッシュ記号にする
	$baseurl =~ s|/$||;		# ベースURLの末尾にスラッシュがあれば一旦消す
	$baseurl .= '/';		# 末尾にスラッシュ記号を足す

	# 付加パスが…
	my $returl = '';
	if( $addpath =~ m|^/| ) {
		# スラッシュで始まっている場合は絶対パスでの指定なので、ベースURLからドメイン部分以外を取り除いてから結合する
		$baseurl =~ s{^((https?://|/)?[^/]+?)/.*$}{$1};		# https:// または / の後からスラッシュ以外の何らかの文字を挟んで最初のスラッシュ記号の直前までだけを残して後は消す。正規表現内に / と | を使うため、{ } で正規表現を区切っている点に注意。
		# 結合する
		$returl = $baseurl . $addpath;
	}
	else {
		# スラッシュ以外の文字で始まっている場合は相対パスなので、そのまま結合する
		$returl = $baseurl . $addpath;
	}

	return $returl;
}

# 														=== ▼汎用 ===

sub checkVer {
	my $reqver = shift @_ || 0;
	return ($vernum - $reqver);
}

# ----------------------------------
# ◆Trim（前後の空白を除外して返す）
# ----------------------------------
sub trim
{
	my $str = shift @_ || '';
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	return $str;
}

# ----------------------------
# ◆配列内すべてをtrimして返す		引数：配列
# ----------------------------
sub alltrim
{
	foreach my $i (0 .. $#_) {
		$_[$i] = trim($_[$i]);
	}
	return @_;
}

# ----------------------------------
# ◆配列内の重複を解消してソートする	引数：配列
# ----------------------------------
sub eliminateDuplication
{
	# 配列要素の重複を削除する
	my %hash	= map { $_ => 1 } @_;
	my @array	= sort keys %hash;

	return @array;
}

# ------------------------------
# ◆縦棒区切りの文字列を行に分解
# ------------------------------
sub pipe2lines
{
	my $str = shift @_ || '';	# データを受け取る

	$str =~ s/\|/\n/g;	# 区切り縦棒記号を改行に変換
	$str .= "\n";		# 最後に改行を加える

	return $str;
}

# -----------------------------------
# ◆行を結合して縦棒区切りの1行にする	引数1：対象データ、引数2：削除する使用禁止文字列を表す正規表現
# -----------------------------------
sub lines2pipe
{
	my $str = shift @_ || return '';	# 対象データ(何もなければ何もしない)
	my $del = shift @_ || '';			# 使用禁止文字(正規表現)

	# 行単位で配列に格納
	my @lines = split(/\r|\n/, $str);	# CR,CR+LF,LFの各パターンに対応するため、CRとLF両方で分割する(一時的に空行ができる)

	# 使用禁止文字が指定されていれば、対象文字列から消す
	if( $del ne '' ) {
		# 使用禁止文字を全部消す
		@lines = map { $_ =~ s/${del}//g; $_ } @lines;
	}

	# 重複項目を削除する
	@lines = &eliminateDuplication( @lines );

	# 空の要素を除いて、縦棒で連結する
	$str = join('|', grep { $_ ne '' } @lines );

	return $str;
}

# ----------------------------
# ◆CSV文字列の末尾に1項目追加		引数1：元のCSV文字列、引数2：加える文字列
# ----------------------------		返値：新しいCSV文字列
sub addcsv
{
	my $csv = shift @_ || '';
	my $add = shift @_ || return $csv;	# 第2引数がないなら第1引数のまま返す

	# CSV文字列が空ではないなら、最後の1文字を調べる
	if(( $csv ne '' ) && ( substr($csv, -1) ne ',' )) {
		# カンマでないならカンマを加える
		$csv .= ',';
	}

	# 加える
	$csv .= $add;

	return $csv;
}

# --------------
# ◆単語検索機能	引数1：対象文字列、引数2：検索条件(検索語)文字列	※整形前のユーザ入力をそのまま渡して可。
# --------------	返値：検索条件に該当=1、非該当=0
sub wordsearch
{
	my $targetstr	= shift @_ || '';
	my $searchstr	= shift @_ || '';

	# 検索語の事前処理
	$searchstr =~ s/　/ /g;			# 全角空白を半角空白にする
	$searchstr =~ s/\s+/ /g;		# 空白系文字の連続を半角空白1つにする
	my @searchwords = split(/ /,$searchstr);		# 空白で分割
	my $needwords = $#searchwords;	# 指定されている検索語数を保持

	# 検索ループ
	my $findcount = 0;
	foreach my $oneword (@searchwords) {
		# 単語を探す
		my $oneword = forsafety( $oneword );	# 検索対象が既に安全化済み文字列なので、ここでも安全化しておく必要がある！(注意)

		# マイナス検索の場合 (※先頭が半角ハイフン「-」記号の場合のみ実行)
		if( $oneword =~ m/^-(.+)/ ) {
			my $quoted_word = quotemeta($1);
			if( $targetstr =~ m/$quoted_word/i ) {		# 大文字・小文字は区別せずに全文検索
				# 見つかったら(除外なので)非該当として関数終了
				return 0;
			}
			else {
				# 見つからなかった場合は、除外対象がなかったので、検索語数から1を引いておいて処理継続
				$needwords--;
			}
		}

		# OR検索の場合 (※検索語の内側に半角縦棒「|」がある場合のみ実行／先頭と末尾に「|」以外の文字があることが必須)
		elsif( $oneword =~ m/.\|./ ) {
			# 縦棒で分割
			my @orwords = split(/\|/,$oneword);	# 縦棒で分割 (※$needwordsに分解個数を加算する必要がない点に注意。OR全体で1件とすれば良いから)
			# OR検索ループ
			foreach my $sepword (@orwords) {
				my $quoted_word = quotemeta($sepword);
				if( $targetstr =~ m/$quoted_word/i ) {		# 大文字・小文字は区別せずに全文検索
					# 1つ見つけたらカウントしてループ終了
					$findcount++;
					last;
				}
			}
		}

		# 通常のAND検索の場合
		my $quoted_word = quotemeta($oneword);
		if( $targetstr =~ m/$quoted_word/i ) {		# 大文字・小文字は区別せずに全文検索
			# 見つかったらカウント
			$findcount++;
		}
	}

	# 発見個数を確認
	if( $findcount <= $needwords ) {
		# 発見個数が検索語数よりも少なければ、検索条件を満たさないので「非該当」を返す
		return 0;
	}

	return 1;	# 該当
}

# ------------------------------------------
# ◆指定文字数だけ切り抜き(マルチバイト対応)	引数1：対象文字列、引数2：切り抜く文字数(Def:10)、引数3：切り抜いた場合の末尾に加える省略文字列(Def:空文字)
# ------------------------------------------
sub mbSubstr
{
	my $target = shift @_ || '';
	my $cutnum = shift @_ || 10;
	my $after  = shift @_ || '';

	if( $cutnum < 1 || $cutnum > 10000 ) { &errormsg('Out of range: at mbSubstr'); }

	# 多バイト文字を正しくカウントするために一旦デコードする
	utf8::decode($target);

	# 切り詰める必要性を確認
	if( length($target) <= $cutnum ) {
		# 充分短い場合はそのまま返す
		utf8::encode($target);
		return $target;
	}

	# 文字列を指定文字数だけ切り抜き
	my $ret = '';
	$cutnum--;
	foreach(0 .. $cutnum){
		my $x = substr($target, $_, 1);
		utf8::encode($x);
		$ret .= $x;
	}

	return $ret . $after;
}

# --------------------------------------------
# ◆指定文字数をカウントする(マルチバイト対応)
# --------------------------------------------
sub mbLength
{
	my $target = shift @_ || '';
	utf8::decode($target);
	return length($target);
}

# --------------------
# ◆行数をカウントする
# --------------------
sub countLines
{
	my $str = shift @_ || '';		# 対象文字列
	my $lfs = shift @_ || "\n";		# 改行だと解釈する文字列

	my @lines = split(/$lfs/, $str);

	my $count = $#lines + 1;

	if( $lines[$#lines] eq '' ) {
		# 最後の行に1文字もないなら、その分はカウントしない
		$count--;
	}

	return $count;
}

# ------------------------------------
# ◆UNIQUERANDを乱数文字列に置き換える
# ------------------------------------
sub uniquerand
{
	my $str = shift @_ || 'UNIQUERAND';

	# 一意にするための乱数
	my $rn = &getrandstr(5);

	# UNIQUERANDを置き換える
	$str =~ s/UNIQUERAND/$rn/g;

	return $str;
}

# ------------------------
# ◆ランダムな英数字を返す	引数：文字数
# ------------------------
sub getrandstr
{
	my $num = shift @_ || 1;	# 個数

	my @strs = ('a'..'z','A'..'Z',0..9);
	my $ret = '';

	for (my $i=0 ; $i<$num ; $i++) {
		$ret .= $strs[int(rand( $#strs + 1 ))];
	}

	return $ret;
}

# ----------------------	引数1：欲しい数値範囲にある整数の個数、引数2：ベースの値(増減値)	／返値：整数（第1引数が0以下なら、返値は常に0）
# ◆ランダムな整数を返す	例えば、1～10のどれかを得たいなら、引数1に 10 を、引数2に 1 を指定する。
# ----------------------	例えば、0～14のどれかを得たいなら、引数1に 15 を、引数2に 0 を指定する。
sub getrandnum
{
	my $max  = shift @_ || 10;	# 範囲の個数
	my $base = shift @_ || 0;	# ベースの値

	# 数値の確認
	$max  = 0 + $max;
	$base = 0 + $base;

	# エラー判定
	if( $max <= 0 ) {
		# 個数の範囲が 0 以下の場合は、無条件で 0 を返す。
		return 0;
	}

	my $ret = int(rand( $max ));
	$ret += $base;

	return $ret;
}

# -------------------
# ◆強制URLエンコード
# -------------------
sub urlencode
{
	my $string = shift @_ || '';
	$string =~ s/(.)/'%'.unpack('H2',$1)/eg;
	return $string;
}

# -----------------------
# ◆部分的なURLエンコード
# -----------------------
sub suburlencode
{
	my $str = shift @_ || '';
	$str =~ s/;/%3B/g;
	$str =~ s/=/%3D/g;
	return $str;
}

# ---------------
# ◆全角数字対策1
# ---------------
sub nozenkakunum
{
	my $string = shift @_ || 0;
	$string =~ s/０/0/g;	$string =~ s/１/1/g;	$string =~ s/２/2/g;	$string =~ s/３/3/g;	$string =~ s/４/4/g;
	$string =~ s/５/5/g;	$string =~ s/６/6/g;	$string =~ s/７/7/g;	$string =~ s/８/8/g;	$string =~ s/９/9/g;
	return $string;
}

# --------------
# ◆全角数字対策2	tr/０-９/0-9/ が使えないので力業。
# --------------
sub nozenkaku
{
	my $string = shift @_ || 0;
	$string =~ s/０/0/g;	$string =~ s/１/1/g;	$string =~ s/２/2/g;	$string =~ s/３/3/g;	$string =~ s/４/4/g;
	$string =~ s/５/5/g;	$string =~ s/６/6/g;	$string =~ s/７/7/g;	$string =~ s/８/8/g;	$string =~ s/９/9/g;
	$string =~ s/．/./g;
	$string =~ s/－/-/g;

	# 数値以外は削除
	$string =~ s/[^0123456789\.-]//g;

	# 数値構成文字の禁則処理
	$string =~ s/[-\.]{2,}//g;		# (2個以上)連続するマイナス記号やドット記号は不正なので削除
	$string =~ s/(.)-/$1/g;			# 先頭以外に存在するマイナス記号は不正なので全て削除
	$string =~ s/^\.//;				# 先頭のドット記号は不正なので削除
	$string =~ s/(\..*?)\./$1/g;	# 2つ目以降のドット記号は不正なので削除

	# 変換の結果として文字列が存在しなくなったら、とりあえず 1 にする
	if( length($string) == 0 ) { $string = '1'; }

	return $string;
}

# ----------------------------------
# ◆1桁の数字を2桁の文字列にして返す
# ----------------------------------
sub addzero
{
	my $targetnum = shift @_ || 0;
	if( $targetnum < 10 && $targetnum >= 0 ) {
		$targetnum = "0" . $targetnum;
	}
	return $targetnum;
}

# -------------------------------------------------
# ◆先頭が0である2桁以上の数字から0を取り除いて返す
# -------------------------------------------------
sub removezero
{
	my $targetnum = shift @_ || 0;
	$targetnum =~ s/0+(\d+)/$1/;
	return $targetnum;
}

# ------------------------------------------
# ◆配列の中から最初に見つかった文字列を返す
# ------------------------------------------
sub retfirststr
{
	foreach my $one (@_) {
		if( length($one) > 0 ) {
			return $one;
		}
	}

	return '';		# 何もなければ空文字列を返す。
}

# ---------------------
# ◆安全用 (エスケープ)
# ---------------------
sub forsafety
{
	my $str = shift @_ || '';

	# エンコード
	$str =~ s|&|&amp;|g;	# アンドを実体参照に
	$str =~ s|<|&lt;|g;		# 小なりを実体参照に
	$str =~ s|>|&gt;|g;		# 大なりを実体参照に
	$str =~ s|"|&quot;|g;	# 二重引用符を実体参照に
	$str =~ s|'|&apos;|g;	# 引用符を実体参照に

	return $str;
}

# ◆安全用の逆(デコード)
sub forunsafety
{
	my $str = shift @_ || '';

	# エンコード
	$str =~ s|&amp;|&|g;	# アンド
	$str =~ s|&lt;|<|g;		# 小なり
	$str =~ s|&gt;|>|g;		# 大なり
	$str =~ s|&quot;|"|g;	# 二重引用符
	$str =~ s|&apos;|'|g;	# 引用符

	return $str;
}

# ◆安全用 (タグ記号と引用符をエスケープ／アンド記号は許可：数値文字参照などを許可するため)
sub forsafetybutand
{
	my $str = shift @_ || '';

	# エンコード
	$str =~ s|<|&lt;|g;		# 小なりを実体参照に
	$str =~ s|>|&gt;|g;		# 大なりを実体参照に
	$str =~ s|"|&quot;|g;	# 二重引用符を実体参照に
	$str =~ s|'|&apos;|g;	# 引用符を実体参照に

	return $str;
}

# ◆安全用 (タグ記号だけをエスケープ)
sub forsafetytag
{
	my $str = shift @_ || '';

	# エンコード
	$str =~ s|<|&lt;|g;		# 小なりを実体参照に
	$str =~ s|>|&gt;|g;		# 大なりを実体参照に

	return $str;
}

# ◆安全用 (切り捨て)
sub safetycutter
{
	my $str = shift @_ || '';

	# 切り抜き
	$str =~ s|['"><&]||g;	# 各記号を削除

	return $str;
}

# ◆安全用 (タグの削除)
sub safetycuttag
{
	my $str = shift @_ || '';

	# タグを削除
	$str =~ s|</?\w+.*?>||g;	# タグを削除

	return $str;
}

# ◆安全用 (ディレクトリ名として使える文字のみ残す)
sub safetydirnamecutter
{
	my $str = shift @_ || '';

	# タグを削除
	$str =~ s/[^\d\w_-]//g;	# 英数字と記号_-以外を削除

	return $str;
}

# ◆安全用 (ファイル名として使える文字のみ残す：open関数に渡すと危険な記号を削除)
sub safetyfilename
{
	my $str = shift @_ || '';	# 第1引数：ファイル名
	my $ife = shift @_ || 0;	# 第2引数：動作種別（0:危険記号を削除して返す／1:エラー終了する／2:エラーを示す値を返す）

	if(( $ife >= 1 ) && ( $str =~ m/[\|+<>\*\?]/ )) {
		# 危険記号があったらエラー
		if( $ife == 1 ) {
			&errormsg('開こうとしているファイル名に、使えない記号 | + &lt; &gt; * ? 等が含まれています。');
		}
		elsif( $ife == 2 ) {
			return '-';			# エラーを示す値として「-」だけを返す
		}
	}

	# 危険記号を削除
	$str =~ s/[\|+<>\*\?]//g;	# | + < > * ? を削除

	return $str;
}

# ◆安全用 (独自の区切り文字を削除)
sub deleteseparators
{
	my $str = shift @_ || '';

	$str =~ s/<>//g;	# 区切り文字<>を削除
	$str =~ s/<,>//g;	# 区切り文字<,>を削除

	return $str;
}

# ◆何も返さない
sub retempty
{
	return '';
}

# ------------------------------------
# ◆てがろぐ記法に使われる文字を安全化
# ------------------------------------
sub encreftegalog
{
	my $str = shift @_ || '';

	$str =~ s|\[|&#91;|g;
	$str =~ s|\]|&#93;|g;
	$str =~ s|:|&#58;|g;

	return $str;
}

# ----------------------------
# ◆てがろぐ記法の安全化を解除
# ----------------------------
sub decreftegalog
{
	my $str = shift @_ || '';

	$str =~ s|&#91;|[|g;
	$str =~ s|&#93;|]|g;
	$str =~ s|&#58;|:|g;

	return $str;
}

# ----------------------------
# ◆改行タグを改行コードに変換
# ----------------------------
sub brtagtoret
{
	my $str = shift @_ || '';	# die 'No string for brtagtoret.';

	$str =~ s|<br>|\n|g;

	return $str;
}

# --------------------------
# ◆改行タグで分割して配列化
# --------------------------
sub brtagtolist
{
	my $str = shift @_ || '';

	my @items = split(/<br>/, $str);

	return @items;
}

# ----------------------------
# ◆改行コードを改行タグに変換
# ----------------------------
sub rettobrtag
{
	my $str = shift @_ || '';	# die 'No string for rettobrtag.';

	$str =~ s|\r?\n|<br>|g;

	return $str;
}

# --------------------------
# ◆指定文字以降をすべて削除		引数1：対象文字列、引数2：それ以降を削除したい文字
# --------------------------		返値：削除した結果の文字列
sub cutafterchar
{
	my $str = shift @_ || &errormsg('No string for cutafterchar.');
	my $char = shift @_ || &errormsg('No char for cutafterchar.');

	# $strの中で$char以降を削除
	if( index($str, $char) != -1 ) {
		# 指定文字があれば、それ以降をカットして返す
		$str = substr($str, 0, index($str, $char));
	}

	# 指定文字がなければそのまま返す
	return $str;
}

# ----------------------------------------------------------------------------
# ◆最後のディレクトリ区切り記号(＝スラッシュまたはバックスラッシュ)以降を得る
# ----------------------------------------------------------------------------
sub getafterlastdirsep
{
	my $str = shift @_ || '';	# &errormsg('No string for getafterlastslash.');

	# スラッシュがあるかどうかを調べる
	if( index($str, '/') != -1 ) {
		# あれば、最後のスラッシュ以降の部分を取得
		if( $str =~ m|/([^/]+)$| ) {
			# 取得できたらそれを返す
			return $1;
		}
		else {
			# 取得できなかったら（最後の文字がスラッシュ）空文字を返す
			return '';
		}
	}

	# バックスラッシュがあるかどうかを調べる
	elsif( index($str, '\\') != -1 ) {
		# あれば、最後のバックスラッシュ以降の部分を取得
		if( $str =~ m|\\([^\\]+)$| ) {
			# 取得できたらそれを返す
			return $1;
		}
		else {
			# 取得できなかったら（最後の文字がバックスラッシュ）空文字を返す
			return '';
		}
	}

	# スラッシュもバックスラッシュもないなら、そのまま返す
	return $str;
}

# ----------------------------
# ◆最後のスラッシュ以降を削除
# ----------------------------
sub cutafterlastslash
{
	my $str = shift @_ || &errormsg('No string for cutafterlastslash.');

	$str =~ s/\A(.+\/).*\z/$1/g;

	return $str;
}

# ----------------------------------
# ◆最後にスラッシュがなければ加える
# ----------------------------------
sub makelastcharslash
{
	my $str = shift @_ || '';

	if( $str !~ m|/$| ) {
		# 最後の文字がスラッシュではなければ加える
		$str .= '/';
	}

	return $str;
}

# -------------------------------------
# ◆2つのPATHをスラッシュ記号で結合する
# -------------------------------------
sub joinwithslash
{
	my $one = shift @_ || '';	# PATH1
	my $two = shift @_ || '';	# PATH2

	return &makelastcharslash( $one ) . $two;
}

# ----------------------------------------------------------------------
# ◆先頭がスラッシュではない場合だけ、ベース文字列をスラッシュで結合する
# ----------------------------------------------------------------------
sub relpathtoabspath
{
	my $base = shift @_ || '';	# ベースPATH
	my $relp = shift @_ || '';	# 相対PATH

	if( $relp !~ m|\A/| ) {
		# 先頭の文字がスラッシュではなければ結合する
		return &makelastcharslash( $base ) . $relp ;
	}

	# 先頭の文字がスラッシュなら、結合せずに第2引数を単独で返す
	return $relp;
}

# ----------
# ◆短縮出力
# ----------
sub tooneline
{
	my $str = shift @_ || '';

	$str =~ s/[\t\r\n]//g;		# 改行・タブを削除
	$str =~ s|/\*.+?\*/||g;		# コメントアウト部分 /* この中 */ を削除

	return $str;
}

# ------------------------------------
# ◆データサイズを単位付き文字列に変換	引数：Bytes数
# ------------------------------------	返値：数値＋単位
sub byteswithunit
{
	my $bytes = shift @_ || 0;

	if( $bytes < 1024 ) {
		return $bytes . "Bytes";
	}
	elsif( $bytes < 1048576 ) {
		return (int(($bytes/1024)*10)/10) . "KB";
	}
	elsif( $bytes < 1073741824 ) {
		return (int(($bytes/1048576)*100)/100) . "MB";
	}
	else {
		return (int(($bytes/1073741824)*100)/100) . "GB";
	}
}

# ライセンスカバー
sub showlccover
{
	my $str = shift @_ || '';
	return ('非表示ライセンス[' . &forsafety($str) . '] ');
}

# --------------------------------------	引数３点：(1)総データ数 (2)1ページあたりの表示数 (3)これから表示するページ番号 ※1～3共:正の整数が前提
# ◆総データ数からページ表示用数値を返す	返値配列：(1)表示を開始すべき番号 (2)表示を終了すべき番号 (3)最終ページ番号 (4)これから表示するページ番号[修正版]
# --------------------------------------	※返値4は、引数3の変数に上書きして返すようにすると、大きすぎるページ番号が指定された際の修正ができる。(使わなくても問題はないが。)
sub calcpagenation
{
	my $totaldata	= shift @_ || 1;	# 総データ数(最低1)
	my $numperpage	= shift @_ || 10;	# 1ページあたりの表示数(とりあえずDef10)
	my $showpagenum	= shift @_ || 1;	# これから表示するページ番号(最低1)

	# ページ番号の超過チェック
	my $endpage = int( $totaldata / $numperpage );		# ページ総数を計算 (例えばデータが計102個あって1P10件ずつなら計11Pまである。※この時点では10が得られる)
	if( ($totaldata % $numperpage) > 0 ) {
		# もし余りがあれば1ページ追加
		$endpage++;
	}
	if( $endpage <= 0 ) { $endpage = 1; }	# データがなくて総ページ数の計算結果が0の場合は1にする。(今の引数の受け取り方だとこの行は常に偽だと思うけど、まあ念のため。)
	if( $showpagenum > $endpage ) {
		# もし指定ページ番号が、実際の最終ページ番号よりも大きければ、強制修正
		$showpagenum = $endpage;
	}

	# 表示すべきデータの範囲を計算
	my $startid = ($numperpage * ($showpagenum - 1)) + 1;	# 何番目から表示開始すればいいかを計算
	my $endid   = ($startid + $numperpage) - 1;				# 何番目まで表示すればいいかを計算
	if( $endid > $totaldata ) { $endid = $totaldata; }		# 表示終了番号がデータ総数を超えていたら、最終番号に修正

	return ( $startid, $endid, $endpage, $showpagenum );
}
# 注意:	※返値の「開始番号」は1から始まるので、そのまま配列の添え字にしてしまわないよう注意。(配列は先頭が0番だが、このサブルーチンが先頭を示す値を返す場合は1になる。)
# 		※データ件数が0個の場合にこのサブルーチンを呼び出すと、最低でも1を返してしまうので、正しくなくなる。(データ件数が1以上ではないなら、このサブルーチンは呼ばないようにする方が望ましい。)

# ------------------------------------		引数：(1)現在ページ番号、(2)最終ページ番号、(3)1ページあたりの表示件数、(4)リンク用URLのベース文字列
# ◆管理画面系のページ移動リンクを生成		返値：必要なリンクを含む完全な(そのまま掲載に使える)HTML
# ------------------------------------		※総ページ数が1なら、空文字列を返す。(ページ移動リンクが不要なので)
sub outputPagenationLinks
{
	my $nowpage = shift @_ || 1;
	my $endpage = shift @_ || 1;
	my $numperpage = shift @_ || 1;
	my $linkbase = shift @_ || '';
	my $pagelink = '';

	if( $endpage > 1 ) {
		# 複数ページある場合のみ
		if( $nowpage > 2 ) {
			# 現在ページが2より大きければ、先頭へ戻るリンクを追加
			$pagelink .= qq|<a href="| . $linkbase . '1' . q|" class="pagenationlink btnlink">&laquo; 先頭へ</a> |;
		}
		if( $nowpage > 1 ) {
			# 現在ページ番号が1より大きければ、前のページが存在する
			$pagelink .= qq|<a href="| . $linkbase . ($nowpage - 1) . qq|" class="pagenationlink btnlink">&lt; 前の$numperpage件</a> |;
		}
		if( $nowpage < $endpage ) {
			# 現在ページ番号が最終ページ未満なら、次のページが存在する
			$pagelink .= qq|<a href="| . $linkbase . ($nowpage + 1) . qq|" class="pagenationlink btnlink">次の$numperpage件 &gt;</a> |;
		}
		if( $nowpage < ($endpage-1) ) {
			# 現在ページが最終ページの1つ前よりも小さいなら、末尾へ飛ぶリンクを追加
			$pagelink .= qq|<a href="| . $linkbase . $endpage . q|" class="pagenationlink btnlink">末尾へ &raquo;</a>|;
		}

		# ページ移動リンクが1つでもあれば出力用に整形
		if( $pagelink ne '' ) {
			$pagelink = qq|<p class="PagenationLinks">$pagelink</p>\n|;
		}
	}

	return $pagelink;
}

# ------------------------------
# ◆ページ番号リストリンクを生成	引数:下記の通り、返値:リンク群HTML
# ------------------------------
sub outputPageListLinks
{
	my $totalpage = shift @_ || 0;					# 引数1:総ページ数
	my $nowpagenum = shift @_ || 0;					# 引数2:現在P番号
	my $pagenumbracket1 = shift @_ || '';			# 引数3:P番号左側記号
	my $pagenumbracket2 = shift @_ || '';			# 引数4:P番号右側記号
	my $pagenumseparator = shift @_ || '';			# 引数5:P番号境界記号
	my $pagefigures = shift @_ || 1;				# 引数6:番号の表示精度
	my $pagenumpmitstart = shift @_ || 13;			# 引数7:P番号を省略する最小総ページ数(標準13)		※v2.10.0で追加
	my $pagenumomission = shift @_ || 0;			# 引数8:P番号の途中を省略(1:する/0:しない)
	my $pagenumomitmark = shift @_ || '…';			# 引数9:途中P省略記号
	my $pagenumalwaysshow = shift @_ || 3;			# 引数10:先頭および末尾からnページは常時表示する	※v2.10.1で追加
	my $classnameforpagenumlink = shift @_ || '';	# 引数11:付加class名
	my $linkbase = shift @_ || '';					# 引数12:リンクに付加するベースパラメータ群(※文字列の末尾は「page=」のようなページ番号を受け取れる形にしておく必要がある点に注意)

	# 引数の問題があれば修正
	if( $pagenumpmitstart < 7 ) { $pagenumpmitstart = 7; }	# P番号を省略する最小総ページ数の最低値は7

	# 生成するリンク群HTMLの格納用
	my $pagelistlinks = '';

	if( $totalpage >= 2 ) {
		# 総ページ数が2以上の場合のみ生成
		my $pagenumcounter = 1;

		# ページ番号の表示/非表示を分ける配列
		my @showpagelink = (0) x ($totalpage + 1);	# 1=Show, 0=Hide ※まず全部0(=Hide)で初期化しておく。注：添え字とページ番号を一致させるために[1]から使う。

		# 総ページ数が指定数を超える場合で、ページ番号リンクの途中を省略する設定の場合
		my $pagenumomitflag = 0;
		if(( $totalpage >= $pagenumpmitstart ) && ( $pagenumomission == 1 )) {
			# 省略フラグを立てる
			$pagenumomitflag = 1;

			# 先頭から3つと、末尾から3つは常時表示(設定で1～3に変更可能)
			$showpagelink[1] = 1;
			$showpagelink[2] = 1 if( $pagenumalwaysshow >= 2 );
			$showpagelink[3] = 1 if( $pagenumalwaysshow >= 3 );
			$showpagelink[$totalpage - 2] = 1 if( $pagenumalwaysshow >= 3 );
			$showpagelink[$totalpage - 1] = 1 if( $pagenumalwaysshow >= 2 );
			$showpagelink[$totalpage    ] = 1;
			# 現在ページの前後1つずつ計3つも表示
			$showpagelink[$nowpagenum - 1] = 1 if( $nowpagenum > 1 );
			$showpagelink[$nowpagenum    ] = 1;
			$showpagelink[$nowpagenum + 1] = 1 if( $nowpagenum < $totalpage );
			# 先頭から走査して、1の次に0が現れた時点で、省略記号を出力できるよう-1を入れる
			my $tempflag = 0;
			foreach my $pn (@showpagelink) {
				if( $pn == 1 ) {
					$tempflag = 1;	# フラグを立てる
				}
				if(( $pn == 0 ) && ($tempflag == 1 )) {
					# フラグが立っていて、値が0なら
					$pn = -1;		# 省略記号を指定
					$tempflag = 0;	# フラグを下ろす
				}
			}
		}

		while( $pagenumcounter <= $totalpage ) {
			# ページごとへのリンクを作成
			my $pagenumlinkclass = $classnameforpagenumlink;	# リンクに付加するclass名
			if( $pagenumcounter == $nowpagenum ) { $pagenumlinkclass = $classnameforpagenumlink . ' pagenumhere'; }
			# ページ番号リンク類を表示するかどうか
			if(( $pagenumomitflag == 0 ) || ( $showpagelink[$pagenumcounter] == 1 )) {
				# 省略フラグが立っていなければ無条件に表示。省略フラグが立っていれば、そのページ番号に対する表示が指示されている場合のみ表示。
				if( $pagenumcounter >= 2 ) {
					# 初回でなければ手前に記号を挿入する
					$pagelistlinks .= $pagenumseparator;
				}
				$pagelistlinks .= qq|$pagenumbracket1<a href="$linkbase$pagenumcounter" class="$pagenumlinkclass">| . sprintf("%.*d", $pagefigures, $pagenumcounter) . qq|</a>$pagenumbracket2 |;
			}
			elsif( $showpagelink[$pagenumcounter] == -1 ) {
				# 省略記号の表示が指示されていれば表示 (ここは省略フラグが立っている場合にしか実行されない)
				if( $pagenumcounter >= 2 ) {
					# 初回でなければ手前に記号を挿入する
					$pagelistlinks .= $pagenumseparator;
				}
				$pagelistlinks .= '<span class="omitmark">' . $pagenumomitmark . '</span> ';
			}
			$pagenumcounter++;
		}
	}

	return $pagelistlinks;
}

# ----------------------------------------------
# ◆属性なしで汎用的に使える要素名の選択肢を返す		引数：対象の指定(inline,block)
# ----------------------------------------------		返値：要素名の配列
sub getStandaloneElementList
{
	my $target = shift @_ || '';

	my @inlines = ('abbr','b','cite','code','data','del','dfn','em','i','ins','kbd','label','mark','q','s','samp','small','span','strong','sub','sup','u','var');
	my @blocks = ('blockquote','div','h1','h2','h3','h4','h5','h6','p','pre');

	if( $target eq 'inline' ) {
		return @inlines;
	}
	elsif( $target eq 'block' ) {
		return @blocks;
	}

	return (@inlines, @blocks);
}

# ---------------
# ◆URLエンコード		引数1：対象文字列、引数2：フラグ群
# ---------------		返値：エンコード結果
sub urlEncode
{
	my $str = shift @_ || '';

	my $encoded = &forsafety($str);
	$encoded =~ s/(\W)/'%'.unpack('H2',$1)/eg;

	return $encoded;
}

# ------------------------------------		POSTのみ許可(POST限定)／GETは拒否
# ◆不正な情報送信を阻止するための確認		引数：拒否する文字列(配列で複数指定可)、※引数がない場合はGETに1文字でもあれば拒否
# ------------------------------------		返値：なし（エラーを直接表示して強制終了）
sub postsecuritycheck
{
	if( $pscheck == 0 ) {
		return 0;			# 確認省略
	}

	# ……………………………………………………………………………
	# (Step.1) GETを拒否する (気軽な実験的試行を防ぐ程度の役割)
	my @reflist = @_;
	my $err = 0;

	if( $#reflist == -1 ) {
		# 引数がない場合は、完全POSTでない限り拒否
		if( $ENV{'QUERY_STRING'} ne '' ) {
			$err = 1;
		}
	}
	else {
		# 引数がある場合はチェック (引数に指定されたパラメータは、GETでは拒否する)
		foreach my $one (@reflist) {
			if( $ENV{'QUERY_STRING'} =~ m/$one/ ) {
				$err = 1;
			}
		}
	}

	if( $err != 0 ) {
		&errormsg('URLに含められないパラメータがURLに含まれています。処理は実行されませんでした。');
		exit;
	}

	# ……………………………………………………………………
	# (Step.2) 不正な場所からリクエストされていないか確認
	my $referer = $cgi->referer();
	my $fullurl = $cgi->url(-full=>1);

	# 参照元がある場合のみ
	if(( $referer ne '' ) && ( $rcheck == 1 )) {
		# 参照元からドメイン名までを抜き出す(ただしプロトコル名は除く)
		$referer =~ s|https?:(//[^/]+).*|$1|;

		# 現在フルパスからプロトコル名を取り除く
		$fullurl =~ s|https?:(//[^/]+).*|$1|;

		# 今のURLが参照元と同じドメイン名なら許可
		if( $fullurl !~ m/^$referer/ ) {
			# 違っていたらエラー
			&errormsg('CGIの設置ドメインとは異なる場所からデータが送信されました。リクエストは受け付けられませんでした。<br>(データ送信元: ' . &forsafety($referer) . ' / 実行位置: ' . &forsafety($fullurl) , ' )<br>');
			exit;
		}
	}

	return 0;
}

# ------------------------------
# ◆汎用のPOST実行フォームを生成		引数：下記
# ------------------------------		返値：HTMLソース
sub makepostexecform
{
	my $action = shift @_ || '';		# 引数1：action属性値
	my $sendlabel = shift @_ || '';		# 引数2：submitボタンのラベル
	my $sendoption = shift @_ || '';	# 引数3：submitボタンに加えるその他の属性群
	my $backlabel = shift @_ || '';		# 引数4：backボタンのラベル(空文字なら出力なし)
	my $backoption = shift @_ || '';	# 引数5：backボタンに加えるその他の属性群(空文字なら「onclick="history.back();"」)
	my @hiddens = @_;					# 引数4以降：「 mode=admin 」の形で name属性値/value属性値 のセットを指定

	my $ret = '';

	# form要素
	$ret = qq|<form action="$action" method="post">|;

	# hidden要素群
	foreach my $one ( @hiddens ) {
		# 属性値を分割
		my $name = '';
		my $value = '';
		($name,$value) = split(/=/, $one);	# イコール記号でnameとvalueに分割

		# name属性値がある場合にだけ生成
		if( $name ne '' ) {
			$value = &forsafety($value);	# value属性値は安全化しておく
			$ret .= qq|<input type="hidden" name="$name" value="$value">|;
		}
	}

	# submitボタン
	$sendlabel = &forsafety($sendlabel);
	$ret .= qq|<input type="submit" value="$sendlabel"$sendoption>|;

	# backボタン
	if( $backlabel ne '' ) {
		# ラベルの指定がある場合だけ出力
		if( $backoption eq '' ) {
			# オプション属性群の指定がない場合はデフォルト属性を出力
			$backoption = 'onclick="history.back();"';
		}
		$backlabel = &forsafety($backlabel);
		$ret .= qq|<input type="button" value="$backlabel" $backoption>|;
	}

	# form要素閉じる
	$ret .= '</form>';

	return $ret;
}

# --------------------------------------------------
# ◆本文の文字数をカウントするために文字列を調整する
# --------------------------------------------------
sub adjustForCharCount
{
	my $str = shift @_ || '';

# &DEBUGOUT("---adjustForCharCount初期\n" . $str);

	# 改行は1文字として扱う
	$str =~ s|&lt;br /&gt;| |g;

	# 画像を取り除く
	$str =~ s|\[PICT:.+?\]||g;

	# …………………………
	# 特殊リンクを取り除く
	# …………………………
	# 画像リンク
	$str =~ s|\[[Ii][Mm][Gg]:(\S*?)\](https?:\/\/[-_.!~*\'()a-zA-Z0-9;\/?:@&=+\$,%#]+)||g;
	# 動画リンク
	$str =~ s|\[[Yy][Oo][Uu][Tt][Uu][Bb][Ee]\]https?:\/\/www\.youtube\.com\/watch\?[-_.!~*\'()a-zA-Z0-9;\/?:@&=+\$,%#]*?v=([-\w]+)[-_.!~*\'()a-zA-Z0-9;\/?:@&=+\$,%#]*||g;
	$str =~ s|\[[Yy][Oo][Uu][Tt][Uu][Bb][Ee]\]https?:\/\/youtu\.be\/([-\w]+)[-_.!~*\'()a-zA-Z0-9;\/?:@&=+\$,%#]*||g;
	# 音楽リンク
	$str =~ s|\[[Ss][Pp][Oo][Tt][Ii][Ff][Yy]\](https?:\/\/open\.spotify\.com\/embed/[-_.!~*\'()a-zA-Z0-9;\/?:@&=+\$,%#]+)||g;
	$str =~ s|\[[Ss][Pp][Oo][Tt][Ii][Ff][Yy]\]https?:\/\/open\.spotify\.com\/([A-Za-z]+?)/([-_.!~*\'()a-zA-Z0-9;\/?:@&=+\$,%#]+)||g;
	# ツイートリンク
	$str =~ s|\[[Tt][Ww][Ee][Ee][Tt]\](https?:\/\/[\w\.]*twitter\.com\/[-_.!~*\'()a-zA-Z0-9;\/?:@&=+\$,%#]*)||g;

	# 投稿番号リンク
	$str =~ s|\[&gt;(\d+)]|$1|g;
	$str =~ s|\[&gt;(\d+):(.+)]|$2|g;	# ラベル付き

	# ………………………………………
	# ラベルリンクはラベルだけにする
	# ………………………………………
	# LBコマンド付きラベル
	$str =~ s|\[([^\[\]#]+?):LB\]https?:\/\/[-_.!~*\'()a-zA-Z0-9;\/?:@&=+\$,%#]+|$1|g;
	# ノーマルラベル
	$str =~ s/\[([^\[\]#]*?)\]https?:\/\/[-_.!~*\'()a-zA-Z0-9;\/?:@&=+\$,%#]+/$1/g;

	# ………………………
	# 装飾記法を取り除く
	# ………………………
	# 角括弧の個数回数だけループすることで、入れ子構造になっていても全数を対象できるようにする。(エスケープ用ループと、装飾用ループの、2回のループで使う)
	my $count = (() = $str =~ /\[/g);

	# 角括弧とコロン記号のエスケープ記法処理
	$str =~ s|\\\[|1|g;		# \[ の記述を1文字としてカウント
	$str =~ s|\\\]|1|g;		# \] の記述を1文字としてカウント
	$str =~ s|\\\:|1|g;		# \: の記述を1文字としてカウント

	# 装飾記法ではない角括弧を1文字としてカウントしておく
	for( my $i = 0; $i < $count ; $i++ ) {
		$str =~ s|\[([^:\[\]]*)\]|o$1o|g;
	}

	# 装飾ループ
	for( my $i = 0; $i < $count ; $i++ ) {
		# 色指定(Color)・マーカー指定(Marker)
		$str =~ s/\[(C|M):([a-fA-F0-9]{6}):([^\[\]]+)\]/$3/g;
		$str =~ s/\[(C|M):([a-z]+):([^\[\]]+)\]/$3/g;
		# 自由装飾指定(Free)
		$str =~ s|\[F:(\w+):([^\[\]]+)\]|$2|g;
		# ルビ(Ruby)
		$str =~ s|\[R:([^\[\]]+?):([^\[\]]+?)\]|$1$2|g;		# comdecorate関数での実装とは異なるので修正する際には注意

		# その他：英字1文字だけの指定
		$str =~ s|\[[BDEHIQSTU]:([^\[\]]+?)\]|$1|g;
	}

	# 続きを読む<>記法を取り除く
	$str =~ s|&lt;&gt;||g;

	# 文字実体参照と数値文字参照を1文字化する
	$str =~ s/(&amp;|&)\w+;/1/g;
	$str =~ s/(&amp;|&)#\d+;/1/g;

# &DEBUGOUT("---adjustForCharCount処理後\n" . $str);

	return $str;
}

# ------------------------------------------------------
# ◆本文の文字数をカウントするために余計な記述を取り除く
# ------------------------------------------------------
sub forCharCount
{
	my $str = shift @_ || '';

	# 改行タグを取り除く
	$str =~ s|<br />| |g;	# 改行を空白1文字として解釈
	# スクリプト要素を取り除く
	$str =~ s|<script.+?</script>||g;
	# HTMLタグを取り除く
	$str =~ s|</?.*?>||g;
	# 文字実体参照と数値文字を1文字化する
	$str =~ s|&\w+;|1|g;
	$str =~ s|&#\d+;|1|g;

	return $str;
}

# ----------------------
# ◆head要素の末尾に挿入	引数1:挿入先のHTML、引数2:挿入する内容
# ----------------------	返値:挿入後のHTML
sub inserttohead
{
	my $insto = shift @_ || '';
	my $str = shift @_ || '';

	# 挿入する </head> または <body> タグを探す
	if( $insto =~ m|</head>|i ) {
		# </head>があるならその直前に挿入
		$insto =~ s|</head>|\t$str\n</head>|i;
	}
	elsif( $insto =~ m|<body|i ) {
		# </head>がなくても<body>があるならその直前に挿入
		$insto =~ s|<body|\t$str\n</head>\n<body|i;
	}

	return $insto;
}

# ----------------------
# ◆Perlバージョンを返す
# ----------------------
sub PerlVersion
{
	if( $^V ) { return sprintf("v%vd", $^V); }		# 文字列化せずにバージョンオブジェクトのままだとPerl 5.8あたりでは何も表示できないので変換が必須。
	return $];
}

# -----------
# ◆for DEBUG
# -----------
sub DEBUGOUT
{
	my $outlog = shift @_ || 'NO LOG';

	open( TESTOUT, ">> temp.log" );
	print TESTOUT $outlog . "\n";
	close TESTOUT;
}


# 														=== ▼管理画面 ===

# --------------------------
# ADMIN：Field：fieldset生成
# --------------------------
sub makefieldset {
	my $fldid	= shift @_ || &errormsg('makefieldset, fldid.','CE');	# フィールドID
	my $fldname	= shift @_ || &errormsg('makefieldset, fldname.','CE');	# フィールド名
	my $helpbox	= shift @_ || '';	# Helpbox
	my $fldsize	= shift @_ || '';	# フィールド最大横幅(CSS用)
	my $fldbody	= shift @_ || &errormsg('makefieldset, fldbody. (' . $fldid . ')' ,'CE');	# フィールド中身

	# 最大横幅が指定されていれば属性を作っておく
	my $maxWidthAtt = '';
	if( $fldsize ne '' ) {
		$maxWidthAtt = ' style="max-width:' . $fldsize . '"';
	}

	# fieldset開始
	my $ret = qq|<fieldset id="fs_$fldid"$maxWidthAtt>|;

	# legend
	$ret .= qq|<legend><a id="$fldid" href="#$fldid">【$fldname】</a></legend>|;

	# helpbox
	if( $helpbox ne '' ) {
		$ret .= qq|<span class="helpbox">$helpbox</span>|;
	}

	# 中身
	$fldbody =~ s/\n\t+//g;		# 改行に続くタブを(改行ごと)すべて削除する (textarea内の文字列を対象にしてしまうのを防ぐために、タブが1個以上ある場合に限る！)
	$ret .= $fldbody;

	# fieldset終了
	$ret .= "</fieldset>\n";

	return $ret;
}

# ---------------------------------
# ADMIN：Field：ヘルプボタン1つ生成
sub makefieldhelpbtn
{
	my $kind	= shift @_ || &errormsg('makefieldhelpbtn, kind.','CE');	# ボタン種別
	my $url		= shift @_ || &errormsg('makefieldhelpbtn, url.','CE');	# リンク先

	return qq|<a class="help $kind" href="$aif{'puburl'}$url">？</a>|;
}
# ----------------------------------
# ADMIN：Field：ヘルプボタン群を生成
sub makefieldhelpbtns
{
	my $btns = shift @_ || return '';	# ボタン情報(複数ある場合はセミコロン区切り) なければ空文字を返す

	my $ret = '';

	my @sepbtns = split(/;/, $btns);	# セミコロンでボタン1件ずつに分離
	foreach my $onebtn ( @sepbtns ) {
		my @btninfo = split(/,/, $onebtn);	# カンマでデータ別に分離
		$ret .= &makefieldhelpbtn( $btninfo[0], $btninfo[1] );
	}

	return $ret;
}

# ------------------------------------
# ADMIN：Field：目次ショートカット生成
sub makeshortcuslinkbox
{
	my $ret = qq|<div class="shortcuslinkbox"><ul class="shortcutlinklist">|;

	foreach my $oneitem ( @_ ) {
		$ret .= qq|<li>$oneitem</li>|;
	}

	$ret .= qq|</ul></div>\n|;

	return $ret;
}

# ------------------------ #
# ◆管理：管理ページの表示 #
# ------------------------ #
sub showadmincore
{
	my $title = shift @_ || '';
	my $status = shift @_ || '';
	my $body = shift @_ || '';
	my $applink = shift @_ || '';
	my $appname = shift @_ || '';
	my $charcode = shift @_ || '';
	my $versionnum = shift @_ || '';
	my $copyrightdate = shift @_ || '';
	my $addfooter = shift @_ || '';
	my $addheader = shift @_ || '';
	my $colortheme = shift @_ || '';
	my $back2home = shift @_ || '';
	my $distinction = shift @_ || '';
	my $tryauli = pack "C*", @auli; my $f = 0;
	my $separator = ' - ';

	if( !length($title) ) {
		$separator = '';
	}

	my @adminhtml = <DATA>;
	foreach my $line (@adminhtml) {
		$line =~ s/_DISTINCTION_/$distinction/g;
		$line =~ s/_WORKTITLE_/$title/g;
		$line =~ s/_SEP_/$separator/g;
		$line =~ s/_APPSIGN_/$applink/g;
		$line =~ s/_APPNAME_/$appname/g;
		$line =~ s/_ADMINHOME_/$back2home/g;
		$line =~ s/_STATUS_/$status/g;
		$line =~ s/_BODY_/$body/g;
		$line =~ s/_FOOTER_/$addfooter/g;
		$line =~ s/_CHARCODE_/$charcode/g;
		$line =~ s/_HEADER_/$addheader/g;
		$line =~ s/_VERSION_/Ver $versionnum/g;
		$line =~ s/_SINCE_/$copyrightdate/g;
		$line =~ s/_THEME_/$colortheme/g;
		if( $line =~ m/$tryauli/ ) { $f++; }
	}

	# ウェブ表示
	print $cgi->header( -type => "text/html" , -charset => $charcode , 'Cache-Control' => 'no-cache' )."\n\n\n" if $f;
	print @adminhtml;
}

# ---------------------- #
# エラーメッセージの出力 #	第1引数=エラーメッセージ／第2引数=移動先リンク文字列	※これはローカル用
# ---------------------- #
sub rbni { return q|<meta name="robots" content="noindex">|; }
sub errormsg
{
	my $msg = shift @_ || 'NO MESSAGE';
	my $linkstr = shift @_ || '';
	my $debugdetail = '';

	if( $flagDebug{'ShowDebugStrings'} == 1 ) {
		$debugdetail = '[PARAMS] ';
		my @params = $cgi->param();
		foreach my $op ( @params ) {
			$debugdetail .= "( $op = " . $cgi->param($op) . ' )';
		}
	}

	# 環境情報の取得
	my $envs .= '<div id="envopen"><input type="button" value="環境情報を表示" onclick="showenv();"></div><div id="envbox"><p class="extrainfo">※なお、お問い合わせの際は、以下の枠内の情報も同時にお知らせ頂けると話が早いかもしれません。</p><ul class="envs">';
	$envs .= '<li>実行環境: Perl ' . &PerlVersion() . ' on ' . $^O . '</li>';
	$envs .= '<li>Included:<ul>';
	foreach my $key (sort keys %INC) {
		$envs .= "<li>" . &forsafety( $key .'： '. $INC{$key} ) . "</li>\n";
	}
	$envs .= '</ul></li><li>環境変数:<ul>';
	foreach my $key (sort keys %ENV) {
		$envs .= "<li>" . &forsafety( $key .'： '. $ENV{$key} ) . "</li>\n";
	}
	$envs .= '</ul></li></ul>';

	# 早い段階でエラーが出た場合のために独自に用意しておく
	my $cgi = new CGI;
	if( $charcode eq '' ) { $charcode = 'UTF-8'; }

	print $cgi->header( -type => "text/html" , -charset => $charcode );
	my $rn = &rbni();
	print << "EOM";
	<html>
	<head>
		<meta name="viewport" content="initial-scale=1">
		$rn
		<title>Fumy Versatile Control Set [ERROR]</title>
		<style>
			body { background-color: #fafafa; font-family: "メイリオ",Meiryo,"Hiragino Kaku Gothic ProN","Hiragino Sans",sans-serif; }
			h1 { font-size: 1.2em; background-color:#cc0000; padding: 3px; font-weight: bold; color: white; }
			.errorbox { padding:1em; margin:1em auto; border:1px solid #eee; background-color:white; border-radius:2em; width:75%; min-width:300px; box-sizing:border-box; }
			#message { border: 1px red dashed; background-color: #fff0f0; font-weight: bold; }
			#message p { margin: 1em 0.5em; }
			#link { text-align:center; }
			.afteralerts { margin: 3em 0 2em; }
			.afteralerts small { color:gray; font-size:0.75em; }
			.contacttoauthor { margin:1em 0; padding:0 0 0 1.5em; }
			.extrainfo { margin: 2.5em 0 0 0; padding: 1.5em 0 0 0; }
			#envopen { text-align:right; }
			#envopen input { font-size:0.7em; }
			.envs { font-size:0.85em; height:10em; min-height:3em; border:1px solid green; overflow:auto; background-color:white; resize:vertical; }
			\@media (max-width: 999px) { .errorbox{ width:auto; } }
		</style>
	</head>
	<body>
		<h1>&#9940; Fumy Versatile Control Set [ERROR]</h1>
		<div class="errorbox">
			<p>CGIの動作中にエラーが発生しました。詳細は以下の通りです。</p>
			<div id="message">
				<p>$msg</p>
			</div>
			<p id="link">$linkstr</p>
			<p>$debugdetail</p>
			<p class="afteralerts">上記の赤枠内に表示されている内容を参考にして対処して下さい。<br><small>※もし上記の赤枠内に「英数字しか表示されていない」または「長い英文が表示されている」ような場合は、プログラムのバグが原因の可能性もあります。その際は、お手数ですが作者まで上記の表示内容をお知らせ頂けますと助かります。</small></p><ul class="contacttoauthor"><li>上記に表示されているエラーが「ファイルが開けない」といった内容の場合は、指定のファイルがちゃんとアップロードされているか、ファイルに読み取り権限または書き込み権限が正しく付加されているか、などを確認して下さい。</li><li>パラメータを自力で組み立ててアクセスしていたり、私製のフォームから情報を送信していたりするわけではない場合で、CGIのソースを特に修正していないにもかかわらずこのエラーが表示される場合は、CGIのバグ(不具合)である可能性が高いです。(^_^;)</li></ul><ul class="contacttoauthor"><li>もし、作者に問い合わせたい場合は、(1)上記の赤枠内に出ているメッセージ、(2)現在のURL、(3)直前にした操作内容……などを併せて、<a href="https://www.nishishi.com/">西村文宏/にしし</a>宛にお知らせ下さい。</li><li>なお、CGIは公式サイトで配布されている最新のバージョンをお使い下さい。その際、CGI本体だけでなく、関連ファイル(.plファイル等)も含めて最新版をお使い頂くようお願い致します。ただし、使用実績がある場合はデータファイルを上書きしてしまわないようご注意下さい。</li></ul>$envs
		</div>
		<script>
			document.getElementById('envbox').style.display = 'none';
			function showenv() {
				document.getElementById('envbox').style.display = 'block';
				document.getElementById('envopen').style.display = 'none';
			}
		</script>
	</body>
	</html>
EOM
	exit;
}


1;

__DATA__
<!DOCTYPE html>
<html lang="ja">
<head>
	<meta charset="_CHARCODE_">
	<meta name="viewport" content="initial-scale=1">
	<title>_DISTINCTION__WORKTITLE__SEP__APPNAME_ _VERSION_</title>
	<style>
		body { background-color:#aaccaa; font-family:"メイリオ",Meiryo,"Hiragino Kaku Gothic ProN","Hiragino Sans",sans-serif; }
		#contents { background-color:#ffffff; border:1px #008000 solid; }
		a:hover { color:red; }
		#header { background-color:#ccffcc; color:#000000; border-bottom:1px green solid; position:relative; }
		h1 { margin:0 0.3em; font-size:1.5em; padding:7px 0; line-height:1; }
		.adminhome a { display:block; width:3em; position:absolute; top:3px; right:3px; padding:3px 0; font-size:0.75em; font-weight:normal; line-height:1; text-decoration:none; background-color:#eee; border-radius:3px; border:1px solid #aaa; color:#005; text-align:center; }
		.workname { font-family:"Lucida Sans Unicode","Microsoft Sans Serif","Century Gothic",sans-serif; }
		.appname { font-size:0.8em; } .appname a { color:#050; text-decoration:none; display:inline-block; } .appname a:hover { text-decoration:underline; }
		#status { margin:0; padding:0.3em 0.5em; text-align:right; font-size:85%; }
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
			#main p:first-child, .sysguide { font-size:0.9em; line-height:1.25; text-align:justify; } ul.sysguide { padding-left:20px; }
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
		.systemmenu li a { display:block; background-color:blue; background-image:linear-gradient( 0deg, #000080, #0080ff ); color:white; border-radius:0.75em; padding:0.5em 1em; margin:0 1px 0.5em 0; text-decoration:none; min-width:5em; line-height:1.5; }
		.systemmenu li a.nop { background-color:gray !important; background-image:linear-gradient( 0deg, #888, #ccc ) !important; cursor:not-allowed; }
		.systemmenu li a span.jp { display:block; text-align:center; font-weight:bold; text-decoration:underline; }
		.systemmenu li a span.en { display:block; text-align:center; font-size:75%; }
		.systemmenucategory { margin:0.5em 0 0.3em 0; font-size:0.9em; color:#008080; }
		.systemmenucategory:first-child { margin-top:0; }
		.systemmenu a:hover { background-image:none; background-color:#ccddff; color:darkblue; }
		.systemmenu a.nop:hover { color:white; }
		.btnlink.statusbtn { margin:3px 0 0 0; padding:0.4em 0.6em; font-size: 0.8em; line-height:1; }
		.inprivate { background-color:#ffd795; border-color:orange; }
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
	</style>
	_HEADER_
</head>
<body class="_THEME_">
	<div id="contents">
		<div id="header">
			<h1><span class="appname">_DISTINCTION_</span><span class="workname">_WORKTITLE_</span>_SEP_<span class="appname">_APPSIGN_ _VERSION_</span></h1><span class="adminhome">_ADMINHOME_</span>
		</div>
		<div id="status">
			_STATUS_
		</div>
		<div id="main">
			_BODY_
		</div>
		<div id="footer">
			_FOOTER_
		</div>
	</div>
	<p id="copyright">
		<!-- ※以下の著作権表示は削除したり改変したりしないでお使い下さい。 -->
		_APPSIGN_ _VERSION_, Copyright &copy; _SINCE_ <a href="https://www.nishishi.com/">にしし/西村文宏</a>.
	</p>
</body>
</html>
