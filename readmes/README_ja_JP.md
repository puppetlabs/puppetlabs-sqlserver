# sqlserver

#### 目次

1. [概要](#概要)
2. [モジュールの説明 - モジュールの機能とその有益性](#モジュールの説明)
3. [セットアップ - sqlserver導入の基本](#セットアップ)
    * [セットアップ要件](#セットアップ要件)
    * [sqlserverを開始する](#sqlserverを開始する)
4. [使用方法 - 構成オプションと追加機能](#使用方法)
    * [SQL Serverツールおよび機能のインストール](#sql-serverインスタンス専用ではないsql-serverツールおよび機能をインストールする)
    * [新しいデータベースの作成](#sql-serverのインスタンス上に新しいデータベースを作成する)
    * [新しいログインの作成](#新しいログインをセットアップする)
    * [新しいログインおよびユーザの作成](#特定のデータベースに新しいログインとユーザを作成する)
    * [ユーザのパーミッションの管理](#上記のユーザのパーミッションを管理する)
    * [カスタムTSQLステートメントの実行](#カスタムのtsqlステートメントを実行する)
5. [参考 - モジュールの機能と動作について](#参考)
6. [制限事項 - OS互換性など](#制限事項)
7. [開発 - モジュール貢献についてのガイド](#開発)

## 概要

sqlserverモジュールは、WindowsシステムにMicrosoft SQL Server 2012および2014をインストールし、管理します。

## モジュールの説明

Microsoft SQL Serverは、Windows用のデータベースプラットフォームです。sqlserverモジュールを利用すると、Puppetを使用して、複数インスタンスのSQL Serverをインストールし、SQL機能とクライアントツールを追加し、TSQLステートメントを実行し、データベース、ユーザ、ロール、サーバ構成オプションを管理できます。

## セットアップ

### セットアップ要件

sqlserverモジュールの要件は次のとおりです。

* Puppet Enterprise 3.7以降
* .NET 3.5. (存在しない場合、自動的にインストールされます。そのためにインターネット接続が必要になる場合があります)
* SQL Server ISOファイルの内容(ローカルまたはネットワーク共有上にマウントまたは展開されていること)
* Windows Server 2012または2012 R2

### sqlserverを開始する

sqlserverモジュールを開始するには、マニフェストに以下のコードを追加します。

```puppet
sqlserver_instance{ 'MSSQLSERVER':
    features                => ['SQL'],
    source                  => 'E:/',
    sql_sysadmin_accounts   => ['myuser'],
}
```

この例では、MS SQLをインストールし、MSSQLSERVERという名前のMS SQLインスタンスを作成します。さらに、SQLの基本機能セット(Data Quality、FullText、Replication、SQLEngine)をインストールし、setup.exeの場所を指定し、新しいSQL専用のsysadminである'myuser'を作成します。

スイッチを使用した、より高度な構成を以下に示します。

```puppet
sqlserver_instance{ 'MSSQLSERVER':
  source                  => 'E:/',
  features                => ['SQL'],
  security_mode           => 'SQL',
  sa_pwd                  => 'p@ssw0rd!!',
  sql_sysadmin_accounts   => ['myuser'],
  install_switches        => {
    'TCPENABLED'          => 1,
    'SQLBACKUPDIR'        => 'C:\\MSSQLSERVER\\backupdir',
    'SQLTEMPDBDIR'        => 'C:\\MSSQLSERVER\\tempdbdir',
    'INSTALLSQLDATADIR'   => 'C:\\MSSQLSERVER\\datadir',
    'INSTANCEDIR'         => 'C:\\Program Files\\Microsoft SQL Server',
    'INSTALLSHAREDDIR'    => 'C:\\Program Files\\Microsoft SQL Server',
    'INSTALLSHAREDWOWDIR' => 'C:\\Program Files (x86)\\Microsoft SQL Server',
  }
}
```

この例では、上の例と同じMS SQLインスタンスを作成しますが、追加のオプションとして、セキュリティモード(パスワード設定が必要)とその他のオプションのインストールスイッチが指定されています。これは、ハッシュシンタックスを使用して指定されます。

## 使用方法

**注**: Microsoft SQL Server用語の明確な定義については、後述の[Microsoft SQL Serverの用語](#microsoft-sql-serverの用語)を参照してください。

### SQL Serverインスタンス専用ではないSQL Serverツールおよび機能をインストールする

```puppet
sqlserver_features { 'Generic Features':
  source   => 'E:/',
  features => ['ADV_SSMS', 'BC', 'Conn', 'SDK', 'SSMS'],
}
```

### SQL Serverのインスタンス上に新しいデータベースを作成する

```puppet
sqlserver::database{ 'minviable':
  instance => 'MSSQLSERVER',
}
```

### 新しいログインをセットアップする

```puppet
SQL Login
sqlserver::login{ 'vagrant':
  instance => 'MSSQLSERVER',
  password => 'Pupp3t1@',
}

# Windowsのログイン
sqlserver::login{ 'WIN-D95P1A3V103\localAccount':
  instance   => 'MSSQLSERVER',
  login_type => 'WINDOWS_LOGIN',
}
```

### 特定のデータベースに新しいログインとユーザを作成する

```puppet
sqlserver::login{ 'loggingUser':
  password => 'Pupp3t1@',
}

sqlserver::user{ 'rp_logging-loggingUser':
  user     => 'loggingUser',
  database => 'rp_logging',
  require  => Sqlserver::Login['loggingUser'],
}
```

### 上記のユーザのパーミッションを管理する

```puppet
sqlserver::user::permissions{'INSERT-loggingUser-On-rp_logging':
    user        => 'loggingUser',
    database    => 'rp_logging',
    permissions => 'INSERT',
    require     => Sqlserver::User['rp_logging-loggingUser'],
}

sqlserver::user::permissions{ 'Deny the Update as we should only insert':
  user        => 'loggingUser',
  database    => 'rp_logging',
  permissions => 'UPDATE',
  state       => 'DENY',
  require     => Sqlserver::User['rp_logging-loggingUser'],
}
```

### カスタムのTSQLステートメントを実行する

#### `sqlserver_tsql`を使用して、他のクラスや定義タイプをトリガする

```puppet
sqlserver_tsql{ 'Query Logging DB Status':
  instance => 'MSSQLSERVER',
  onlyif   => "IF (SELECT count(*) FROM myDb.dbo.logging_table WHERE
      message like 'FATAL%') > 1000  THROW 50000, 'Fatal Exceptions in Logging', 10",
  notify   => Exec['Too Many Fatal Errors']
}
```

#### 条件付きチェックで通常ログをクリーンアップする

```puppet
sqlserver_tsql{ 'Cleanup Old Logs':
  instance => 'MSSQLSERVER',
  command  => "DELETE FROM myDb.dbo.logging_table WHERE log_date < '${log_max_date}'",
  onlyif   => "IF exists(SELECT * FROM myDb.dbo.logging_table WHERE log_date < '${log_max_date}')
      THROW 50000, 'need log cleanup', 10",
}
```

#### ステートメントを常に実行させるには、`onlyif`パラメータを取り除きます。

```puppet
sqlserver_tsql{ 'Always running':
  instance => 'MSSQLSERVER',
  command  => 'EXEC notified_executor()',
}
```

### 高度な例

この高度な例について:

* 基本的なSQL Server Engineを、'D:\'にマウントされたインストールメディアを使ってインストールします。インストールの際は、TCPを有効にし、各種ディレクトリを設定します。

* Windowsベースの認証のみを使用し、Puppetを実行しているユーザとしてのみインストールします。'sql_sysadmin_accounts'はインスタンスのインストール時にのみ適用され、その後は選択しない限り適用されないので注意が必要です。

* 後続のリソースが新規作成されたリソースに接続するために使われる、`sqlserver::config`リソースを作成します。Windowsベースの認証のみサポートしているため、ユーザ名とパスワードは必要ありません。

* 'DB Administrators'という名前のローカルグループを作成し、このグループがSQLシステム管理者(sysadminロール)であることを確認します。また、Puppetがインスタンスのインストールと管理に使用するアカウントも作成します。

* Puppetがインスタンスの'max memory'設定を管理できるように、`sp_configure`の詳細オプションが有効になっていることを確認します。

* `max memory` (MB)構成アイテムが2048メガバイトに設定されていることを確認します。

```puppet
$sourceloc = 'D:/'

# SQL Serverのデフォルトインスタンスをインストールする
sqlserver_instance{'MSSQLSERVER':
  source                => $sourceloc,
  features              => ['SQLEngine'],
  sql_sysadmin_accounts => [$facts['id']],
  install_switches      => {
    'TCPENABLED'          => 1,
    'SQLBACKUPDIR'        => 'C:\\MSSQLSERVER\\backupdir',
    'SQLTEMPDBDIR'        => 'C:\\MSSQLSERVER\\tempdbdir',
    'INSTALLSQLDATADIR'   => 'C:\\MSSQLSERVER\\datadir',
    'INSTANCEDIR'         => 'C:\\Program Files\\Microsoft SQL Server',
    'INSTALLSHAREDDIR'    => 'C:\\Program Files\\Microsoft SQL Server',
    'INSTALLSHAREDWOWDIR' => 'C:\\Program Files (x86)\\Microsoft SQL Server'
  }
}

# DBインスタンスに接続するためのリソース
sqlserver::config { 'MSSQLSERVER':
  admin_login_type => 'WINDOWS_LOGIN'
}

# SQL Server Administratorsを適用する
$local_dba_group_name = 'DB Administrators'
$local_dba_group_netbios_name = "${facts['hostname']}\\DB Administrators"

group { $local_dba_group_name:
  ensure => present
}

-> sqlserver::login { $local_dba_group_netbios_name :
  login_type  => 'WINDOWS_LOGIN',
}

-> sqlserver::role { 'sysadmin':
  ensure   => 'present',
  instance => 'MSSQLSERVER',
  type     => 'SERVER',
  members  => [$local_dba_group_netbios_name, $facts['id']],
}

# メモリ消費を適用する
sqlserver_tsql {'check advanced sp_configure':
  command => 'EXEC sp_configure \'show advanced option\', \'1\'; RECONFIGURE;',
  onlyif => 'sp_configure @configname=\'max server memory (MB)\'',
  instance => 'MSSQLSERVER'
}

-> sqlserver::sp_configure { 'MSSQLSERVER-max memory':
  config_name => 'max server memory (MB)',
  instance => 'MSSQLSERVER',
  reconfigure => true,
  restart => true,
  value => 2048
}
```

## 参考

### タイプ

特に指定のない限り、パラメータの指定は任意です。

#### `sqlserver_features`

SSMSやMaster Data Serviceなどの機能をインストールおよび構成します。

##### `ensure`

管理対象の機能が存在するかどうかを指定します。有効なオプション: 'present'および'absent'。

デフォルト値: 'present'。

##### `features`

*必須。*

管理する機能を1つまたは複数指定します。有効なオプション: 'BC'、'Conn'、'SSMS'、'ADV_SSMS'、'SDK'、'IS'、'MDS'、'BOL'、'DREPLAY_CTLR'、'DREPLAY_CLT'。

この設定の'Tools'値は廃止されました。'BC'、'SSMS'、'ADV_SSMS'、'Conn'、'SDK'のいずれかのみを指定してください。

##### `install_switches`

1つまたは複数のインストーラスイッチをSQL Serverセットアップに受け渡します。あるオプションが個別のパラメータと`install_switches`の両方で指定されている場合、個別に指定されたパラメータが優先されます。例えば、`pid`と`install_switches`の両方にプロダクトキーが設定されている場合、SQL Serverは`pid`パラメータを優先します。有効なオプション: 配列。

> **注**: あるオプションが個別のパラメータと`install_switches`の両方で指定されている場合、個別に指定されたパラメータが優先されます。例えば、`pid`と`install_switches`の両方にプロダクトキーが設定されている場合、SQL Serverは`pid`パラメータを優先します。
>
> インストーラスイッチの詳細とSQL Serverの構成方法については、次のリンクを参照してください。
>
> * [インストーラスイッチ](https://msdn.microsoft.com/en-us/library/ms144259.aspx)
> * [構成ファイル](https://msdn.microsoft.com/en-us/library/dd239405.aspx)


デフォルト値: {}。

##### `is_svc_account`

Integration Servicesによって使用されるドメインアカウントまたはシステムアカウントを指定します。有効なオプション: 既存のユーザ名を指定する文字列。デフォルト値: 'NT AUTHORITY\NETWORK SERVICE'。

##### `is_svc_password`

*`is_svc_account`にドメインアカウントが設定されている場合、指定は必須です。システムアカウントの場合は無効です。*

Integration Servicesのユーザアカウントのパスワードを提供します。有効なオプション: 有効なパスワードを指定する文字列。

##### `pid`

SQL Serverのプロダクトキーを指定します。有効なオプション: 有効なプロダクトキーを含む文字列。指定しない場合、SQL Serverは評価モードで動作します。

デフォルト値: `undef`。

##### `source`

*必須。*

SQL Server installerの場所を指定します。有効なオプション: 実行ファイルへのパスを含む文字列。Puppetは、インストーラを実行可能なパーミッションを持つ必要があります。

##### `windows_feature_source`

Windows Featureソースファイルの場所を指定します。これは、.Net Frameworkのインストールに必要になる場合があります。詳細については、https://support.microsoft.com/en-us/kb/2734782を参照してください。

#### `sqlserver_instance`

SQL Serverインスタンスをインストールし、構成します。

##### `agt_svc_account`

SQL Server Agentサービスによって使用されるドメインアカウントまたはシステムアカウントを指定します。

有効なオプション: 既存のユーザ名を指定する文字列。

##### `agt_svc_password`

*`agt_svc_account`にドメインアカウントが設定されている場合、指定は必須です。システムアカウントの場合は無効です。*

Agentサービスユーザアカウントのパスワードを提供します。

有効なオプション: 有効なパスワードを指定する文字列。

##### `as_svc_account`

Analysis Servicesによって使用されるドメインアカウントまたはシステムアカウントを指定します。

有効なオプション: 既存のユーザ名を指定する文字列。

##### `as_svc_password`

*`as_svc_account`が指定されている場合、指定は必須です。*

Analysis Servicesユーザアカウントのパスワードを提供します。

有効なオプション: 有効なパスワードを指定する文字列。

##### `as_sysadmin_accounts`

*`features`配列に値'AS'が含まれている場合、指定は必須です。*

sysadminステータスを受け取る1つまたは複数のSQLアカウントまたはドメインアカウントを指定します。

有効なオプション: 1つまたは複数の有効なユーザ名を指定する配列。

##### `ensure`

管理対象のインスタンスが存在するかどうかを指定します。有効なオプション: 'present'および'absent'。

デフォルト値: 'present'。

##### `features`

*必須。* 管理する機能を1つまたは複数指定します。最上位機能のリストには、AS'と'RS'が含まれます。有効なオプション: 'SQL'、'SQLEngine'、'Replication'、'FullText'、'DQ'、'AS'、'RS'、'POLYBASE'、'ADVANCEDANALYTICS'の文字列のうち、1つまたは複数を含む配列。

この設定の'SQL'値は廃止されました。'DQ'、'FullText'、'Replication'、'SQLEngine'のいずれかのみを指定してください。

##### `install_switches`

SQL Server Instance Setupに1つまたは複数の追加インストーラスイッチを受け渡します。有効なオプション: [インストーラスイッチ](https://msdn.microsoft.com/en-us/library/ms144259.aspx)のハッシュ値。

> **注**: あるオプションが個別のパラメータと`install_switches`の両方で指定されている場合、個別に指定されたパラメータが優先されます。例えば、`pid`と`install_switches`の両方にプロダクトキーが設定されている場合、SQL Serverは`pid`パラメータを優先します。
>
> インストーラスイッチの詳細とSQL Serverの構成方法については、次のリンクを参照してください。
>
> * [インストーラスイッチ](https://msdn.microsoft.com/en-us/library/ms144259.aspx)
> * [構成ファイル](https://msdn.microsoft.com/en-us/library/dd239405.aspx)

##### `name`

インスタンスの名前を提供します。有効なオプション: [有効なインスタンス名](https://msdn.microsoft.com/en-us/library/ms143531.aspx)を含む文字列。

デフォルト値: 宣言したリソースの既存のタイトル。

##### `pid`

SQL Serverのプロダクトキーを指定します。有効なオプション: 有効なプロダクトキーを含む文字列。指定しない場合、SQL Serverは評価モードで動作します。

デフォルト値: `undef`。

##### `polybase_svc_account`

** SQL Server 2016のPOLYBASE 機能がインストールされている場合にのみ該当します。**

Polybase Engineサービスによって使用されるドメインアカウントまたはシステムアカウントを指定します。

有効なオプション: 既存のユーザ名を指定する文字列。

##### `polybase_svc_password`

** SQL Server 2016のPOLYBASE 機能がインストールされている場合にのみ該当します。**

Polybase Engineサービスのパスワードを指定します。

有効なオプション: 有効なパスワードを指定する文字列。

##### `rs_svc_account`

レポートサービスによって使用されるドメインアカウントまたはシステムアカウントを指定します。有効なオプション: `'"/ \ [ ] : ; | = , + * ? < >'`を含まない文字列。ドメインユーザアカウントを指定する場合、ドメインは254文字未満、ユーザ名は20文字未満である必要があります。

デフォルト値: 現在のオペレーティングシステムのデフォルトのビルトインアカウント(`NetworkService`または`LocalSystem`のいずれか)。

##### `rs_svc_password`

*`rs_svc_account`にドメインアカウントが指定されている場合、指定は必須です。システムアカウントの場合は無効です。* 

レポートサーバのユーザアカウントのパスワードを提供します。有効なオプション: 強力なパスワードを成す文字列(8文字以上、大文字と小文字の両方と1つ以上の記号を含むこと。辞書に載っているような一般的な単語や名称は避けること)。

##### `sa_pwd`

*`security_mode`が'SQL'に設定されている場合、設定は必須です。*

SQL Serverのsaアカウントのパスワードを設定します。有効なオプション: 有効なパスワードを指定する文字列。

##### `security_mode`

SQL Serverのセキュリティモードを指定します。有効なオプション: 'SQL'。指定しない場合、SQL ServerはWindows認証を使用します。

デフォルト値: `undef`。

##### `source`

*必須。*

SQL Server installerの場所を指定します。有効なオプション: 実行ファイルへのパスを含む文字列。Puppetは、インストーラを実行可能なパーミッションを持つ必要があります。

##### `sql_svc_account`

SQL Serverサービスによって使用されるドメインアカウントまたはシステムアカウントを指定します。有効なオプション: 既存のユーザ名を指定する文字列。

デフォルト値: `undef`。

##### `sql_svc_password`

*`sql_svc_account`にドメインアカウントが指定されている場合、指定は必須です。システムアカウントの場合は無効です。* 

SQL Serverサービスユーザアカウントのパスワードを提供します。有効なオプション: 有効なパスワードを指定する文字列。

##### `sql_sysadmin_accounts`

*必須。*

sysadminステータスを受け取る1つまたは複数のSQLアカウントまたはシステムアカウントを指定します。有効なオプション: 1つまたは複数の有効なユーザ名を指定する配列。

##### `windows_feature_source`

Windows Featureソースファイルの場所を指定します。これは、.Net Frameworkのインストールに必要になる場合があります。詳細については、https://support.microsoft.com/en-us/kb/2734782を参照してください。

#### `sqlserver_tsql`

SQL Serverインスタンスに対し、TSQLクエリを実行します。

親インスタンスにアクセスするために`sqlserver::config`定義タイプが必要です。

##### `command`

実行するTSQLステートメントを提供します。有効なオプション: 文字列。

##### `instance`

*必須。*

ステートメントを実行するSQL Serverインスタンスを指定します。有効なオプション: 既存のインスタンス名を含む文字列。

デフォルト値: 'MSSQLSERVER'。

##### `database`

接続先のデフォルトデータベースを指定します。デフォルト値: 'master'。

##### `onlyif`

`command`ステートメントを実行する前に実行し、前進するかどうかを決定するTSQLステートメントを提供します。`onlyif`ステートメントがTHROWまたは何らかの非標準的な終了で終わる場合、Puppetは`command`ステートメントを実行します。有効なオプション: 文字列。

### 定義タイプ

特に指定のない限り、パラメータの指定は任意です。

#### `sqlserver::config`

指定されたSQL Serverインスタンスを管理する際に使用するPuppetの資格情報を格納します。

##### `admin_login_type`

SQL Serverインスタンスを管理するために使用するログインのタイプを指定します。このログインタイプは、後述する`admin_user`および`admin_pass` パラメータに影響します。有効なオプション: 'SQL_LOGIN'および'WINDOWS_LOGIN'。

デフォルト値: 'SQL_LOGIN'。

- SQL Serverベースの認証を使用する場合 - `SQL_LOGIN`

    * `admin_pass`: *必須。* 指定された`admin_user`アカウントのパスワードを提供します。有効なオプション: 有効なパスワードを指定する文字列。

    * `admin_user`: *必須。* サーバのsysadmin権限をもつログインアカウントを指定します。これは、インスタンスの管理に使用します。有効なオプション: ユーザ名を含む文字列。

- Windowsベースの認証を使用する場合 - `WINDOWS_LOGIN`

    * `admin_pass`: 有効なオプション: 未定義または空の文字列`''`

    * `admin_user`: 有効なオプション: 未定義または空の文字列`''`

##### `instance_name`

管理対象のSQL Serverインスタンスを指定します。有効なオプション: 既存のインスタンス名を含む文字列。

デフォルト値: 宣言したリソースのタイトル。

#### `sqlserver::database`

指定されたSQL Serverインスタンス内でデータベースを作成および構成します。

親インスタンスにアクセスするために`sqlserver::config`定義タイプが必要です。

##### `collation_name`

データベースのデフォルトの並び順の元となるディクショナリを指定します。有効なオプション: お使いのシステムがサポートしている値を調べるには、クエリ`SELECT * FROM sys.fn_helpcollations() WHERE name LIKE 'SQL%'`を実行します。

デフォルト値: `undef`。

##### `compatibility`:

データベースが互換性をもつSQL Serverのバージョンを1つまたは複数指定します。有効なオプション: 互換性レベル番号(例: SQL Server 2008～SQL Server 2014では100)。値の一覧については[SQL Serverドキュメント](http://msdn.microsoft.com/en-us/library/bb510680.aspx)を参照してください。

##### `containment`

データベースのコンテインメントの種類を設定します。コンテインメントの詳細については、[SQL Serverドキュメント](http://msdn.microsoft.com/en-us/library/ff929071.aspx)を参照してください。有効なオプション: 'NONE'および'PARTIAL' ('PARTIAL'には`sqlserver::sp_configure`定義タイプが必要です)。

デフォルト値: 'NONE'。

##### `db_chaining`

管理対象のデータベースがデータベース間の所有権チェーンのソースになるか、ターゲットになるかを指定します。`containment`が'PARTIAL'に設定されている場合のみ有効です。有効なオプション: 'ON'および'OFF'。

デフォルト値: 'OFF'。

##### `db_name`: *必須。*

管理対象のデータベースを指定します。有効なオプション: データベース名を含む文字列。

デフォルト値: 宣言したリソースのタイトル。

##### `default_fulltext_language`

デフォルトのフルテキスト言語を設定します。`containment`が'PARTIAL'に設定されている場合のみ有効です。有効なオプション: [SQL Serverドキュメント](http://msdn.microsoft.com/en-us/library/ms190303.aspx)を参照してください。

デフォルト値: 'English'。

##### `default_language`

デフォルト言語を設定します。`containment`が'PARTIAL'に設定されている場合のみ有効です。有効なオプション: [SQL Serverドキュメント](http://msdn.microsoft.com/en-us/library/ms190303.aspx)を参照してください。

デフォルト値: 'us_english'。

##### `ensure`

管理対象のデータベースが存在するかどうかを指定します。有効なオプション: 'present'および'absent'。

デフォルト値: 'present'。

##### `filespec_filegrowth`

filespecファイルの自動増分量を指定します。`os_file_name`がUNCパスに設定されている場合は指定できません。このパラメータは作成時のみに設定され、アップデートの影響を受けません。有効なオプション: `filespec_maxsize`の値以下の数値。オプションで接尾文字'KB'、'MB'、'GB'または'TB'を含めることができます。接尾文字を付けない場合、SQL Serverは単位をMBとみなします。

デフォルト値: `undef`。

##### `filespec_filename`

*`filespec_name`が指定されている場合、設定は必須です。*

filespecファイルのオペレーティングシステム(物理)名を指定します。このパラメータは作成時のみに設定され、アップデートの影響を受けません。有効なオプション: 絶対パスを含む文字列。

デフォルト値: `undef`。

##### `filespec_maxsize`

filespecファイルが取り得る最大サイズを指定します。`os_file_name`がUNCパスに設定されている場合は指定できません。このパラメータは作成時のみに設定され、アップデートの影響を受けません。有効なオプション: 2147483647以下の数値。オプションで接尾文字'KB'、'MB'、'GB'、または'TB'を含めることができます。接尾文字を付けない場合、SQL Serverは単位をMBとみなします。

デフォルト値: `undef`。

##### `filespec_name`

*`filespec_filename`が指定されている場合、設定は必須です。*

SQL Serverインスタンス内のfilespecオブジェクトの論理名を指定します。このパラメータは作成時のみに設定され、アップデートの影響を受けません。有効なオプション: 文字列。インスタンスに対して一意である必要があります。

デフォルト値: `undef`。

##### `filespec_size`

filespecファイルのサイズを指定します。このパラメータは作成時のみに設定され、アップデートの影響を受けません。有効なオプション: 2147483647以下の数値。オプションで接尾文字'KB'、'MB'、'GB'または'TB'を含めることができます。接尾文字を付けない場合、SQL Serverでは単位をMBとみなされます。

デフォルト値: `undef`。

##### `filestream_directory_name`

ファイルストリームデータを保存するディレクトリを指定します。このオプションは、データベースにFileTableを作成する前に設定する必要があります。このパラメータは作成時のみに設定され、アップデートの影響を受けません。`sqlserver::sp_configure`定義タイプが必要です。有効なオプション: Windows互換ディレクトリ名を含む文字列。この名前は、SQL Serverインスタンス内のすべてのDatabase_Directory名の中で一意である必要があります。一意性の判断では、SQL Serverの照合設定にかかわらず、大文字と小文字は区別されません。

デフォルト値: `undef`。

##### `filestream_non_transacted_access`

データベースへのトランザクションなしのFILESTREAMアクセスのレベルを指定します。このパラメータは作成時のみに設定され、アップデートの影響を受けません。`sqlserver::sp_configure`定義タイプが必要です。有効なオプション: 'OFF'、'READ_ONLY'、'FULL'。 

デフォルト値: `undef`。

##### `instance`

データベースを管理するSQL Serverインスタンスを指定します。有効なオプション: 既存のインスタンス名を含む文字列。

デフォルト値: 'MSSQLSERVER'。

##### `log_filegrowth`

ログファイルの自動増分量を指定します。`os_file_name`がUNCパスに設定されている場合は指定できません。FILESTREAMファイルグループには適用されません。このパラメータは作成時のみに設定され、アップデートの影響を受けません。有効なオプション: `log_maxsize`の値以下の数値。オプションで接尾文字'KB'、'MB'、'GB'または'TB'を含めることができます。接尾文字を付けない場合、SQL Serverは単位をMBとみなします。

デフォルト値: `undef`。

##### `log_filename`

*`log_name`が指定されている場合、設定は必須です。*

ログファイルのオペレーティングシステム(物理)名を指定します。このパラメータは作成時のみに設定され、アップデートの影響を受けません。有効なオプション: 絶対パスを含む文字列。

デフォルト値: `undef`。

##### `log_maxsize`
ログファイルが取り得る最大サイズを指定します。`os_file_name`がUNCパスに設定されている場合は指定できません。このパラメータは作成時のみに設定され、アップデートの影響を受けません。有効なオプション: 2147483647以下の数値。オプションで接尾文字'KB'、'MB'、'GB'、または'TB'を含めることができます。接尾文字を付けない場合、SQL Serverは単位をMBとみなします。

デフォルト値: `undef`。

##### `log_name`

*`log_filename`が指定されている場合、設定は必須です。*

SQL Server内のログオブジェクトの論理名を指定します。このパラメータは作成時のみに設定され、アップデートの影響を受けません。有効なオプション: 文字列。

デフォルト値: `undef`。

##### `log_size`

ファイルのサイズを指定します。このパラメータは作成時のみに設定され、アップデートの影響を受けません。有効なオプション: 2147483647以下の数値。オプションで接尾文字'KB'、'MB'、'GB'または'TB'を含めることができます。接尾文字を付けない場合、SQL Serverは単位をMBとみなします。

デフォルト値: `undef`。

##### `nested_triggers`

カスケーディングトリガを有効にするかどうかを指定します。`containment`が'PARTIAL'に設定されている場合のみ有効です。トリガのネストの詳細については、[SQL Serverドキュメント](http://msdn.microsoft.com/en-us/library/ms178101.aspx)を参照してください。有効なオプション: 'ON'および'OFF'。マニュアル

デフォルト値: `undef`。

##### `transform_noise_words`

"is"、"the"、"this"などのノイズやストップワードを削除するかどうかを指定します。`containment`が'PARTIAL'に設定されている場合のみ有効です。有効なオプション: 'ON'および'OFF'。

デフォルト値: `undef`。

##### `trustworthy`

インパーソネーションコンテキストを使用するデータベースモジュール(ビュー、ユーザ定義関数、ストアドプロシージャなど)がデータベース外部のリソースにアクセスできるかどうかを指定します。`containment`が'PARTIAL'に設定されている場合のみ有効です。有効なオプション: 'ON'および'OFF'。 

デフォルト値: 'OFF'。

##### `two_digit_year_cutoff`

システムが年を2桁ではなく4桁として扱う年を設定します。たとえば、'1999'に設定した場合、1998年は'98'、2014年は'2014'に略されます。`containment`が'PARTIAL'に設定されている場合のみ有効です。有効なオプション: 1753～9999までの任意の年。

デフォルト値: 2049。

>SQL Serverにおけるこれらの設定の詳細については、以下を参照してください。
>
> * [包含データベース](http://msdn.microsoft.com/en-us/library/ff929071.aspx)
> * [データベースのTSQLを作成する](http://msdn.microsoft.com/en-us/library/ms176061.aspx)
> * [データベースのTSQLを変更する](http://msdn.microsoft.com/en-us/library/ms174269.aspx)
> * [システム言語](http://msdn.microsoft.com/en-us/library/ms190303.aspx)
>
> FILESTREAMを使用するには、SQL Serverを手動で構成する作業が必要になる場合があります。詳細については、[FILESTREAMの有効化と構成](http://msdn.microsoft.com/en-us/library/cc645923.aspx)を参照してください。

#### `sqlserver::login`

`sqlserver::config`定義タイプが必要です。

##### `check_expiration`:

パスワード失効時にSQL Serverがユーザにパスワードの変更を促すかどうかを指定します。`login_type`が'SQL_LOGIN'に設定されている場合のみ有効です。有効なオプション: `true`および`false`。

デフォルト値: `false`。

##### `check_policy`

パスワードポリシーを強制するかどうかを指定します。`login_type`が'SQL_LOGIN'に設定されている場合のみ有効です。有効なオプション: `true`および`false`。

デフォルト値: `true`。

##### `default_database`

そのログインがデフォルトで接続するデータベースを指定します。有効なオプション: 既存のデータベース名を含む文字列。

デフォルト値: 'master'。

##### `default_language`

デフォルト言語を指定します。有効なオプション: [SQL Serverドキュメント](http://msdn.microsoft.com/en-us/library/ms190303.aspx)を参照してください。

デフォルト値: 'us_english'。

##### `disabled`

管理対象のログインを無効化するかどうかを指定します。有効なオプション: `true`および`false`。 

デフォルト値: `false`。

##### `ensure`

管理対象のログインが存在するかどうかを指定します。有効なオプション: 'present'および'absent'。

デフォルト値: 'present'。

##### `instance`

ログインを管理するSQL Serverインスタンスを指定します。有効なオプション: 既存のインスタンス名を含む文字列。

デフォルト値: 'MSSQLSERVER'。

##### `login`

*必須。*

管理対象のWindowsログインまたはSQLログインを指定します。有効なオプション: 既存のログインを含む文字列。

##### `login_type`

使用するログインのタイプを指定します。有効なオプション: 'SQL_LOGIN'および'WINDOWS_LOGIN'。

デフォルト値: 'SQL_LOGIN'。

##### `password`

*`login_type`が'SQL_LOGIN'に設定されている場合、設定は必須です。*

管理対象のログインのパスワードを設定します。有効なオプション:  文字列。

##### `svrroles`

ログインに1つまたは複数の事前インストールされたサーバロールを割り当てます。有効なオプション: `permission => value`ペアのハッシュ値。ここで値0は無効、値1は有効であることを示します。たとえば、`{'diskadmin' => 1、'dbcreator' => 1、'sysadmin' => 0}`などです。有効なパーミッションの一覧については、[SQL Serverドキュメント](http://msdn.microsoft.com/en-us/library/ms188659.aspx)を参照してください。

> **SQL Serverにおけるこれらの設定の詳細については、以下を参照してください。**
> 
> * [サーバロールメンバ](http://msdn.microsoft.com/en-us/library/ms186320.aspx)
> * [ログインを作成](http://technet.microsoft.com/en-us/library/ms189751.aspx)
> * [ログインを変更](http://technet.microsoft.com/en-us/library/ms189828.aspx)

#### `sqlserver::login::permissions`

指定されたログインアカウントに関連付けられるパーミッションを構成します。

##### `instance`

パーミッションを管理するSQL Serverインスタンスを指定します。有効なオプション: 既存のインスタンス名を含む文字列。

デフォルト値: 'MSSQLSERVER'。

##### `login`

*必須。*

管理対象のSQLまたはWindowsログインを指定します。有効なオプション: 既存のログインを含む文字列。

##### `permissions`

*必須。*

管理対象の1つまたは複数のパーミッションを指定します。有効なオプション: 文字列または文字列の配列。各文字列には[SQL Serverパーミッション](https://technet.microsoft.com/en-us/library/ms191291%28v=sql.105%29.aspx) (例: 'SELECT'、'INSERT'、'UPDATE'、'DELETE'など)を含みます。

##### `state`

指定したパーミッションの状態を決定します。有効なオプション: 'GRANT'、'DENY'、'REVOKE'。'REVOKE'に設定すると、Puppetはこれらのパーミッションの明示的ステートメントをすべて削除し、継承されたレベルにフォールバックします。

デフォルト値: 'GRANT'。

##### `with_grant_option`

アカウントがこれらのパーミッションを他者に付与することができるかを指定します。有効なオプション: `true`および`false`。

デフォルト値: `false`。

#### `sqlserver::user`

指定されたデータベース内のユーザアカウントを作成および構成します。

親インスタンスにアクセスするために`sqlserver::config`定義タイプが必要です。

##### `database`

*必須。*

ユーザを管理するデータベースを指定します。有効なオプション: 既存のデータベース名を含む文字列。

##### `default_schema`

ユーザがデフォルトで接続するSQLスキーマまたは名前空間を指定します。有効なオプション: 文字列。

デフォルト値: サーバレベルで変更されていない限り'dbo'。

##### `ensure`

管理対象のユーザが存在するかどうかを指定します。有効なオプション: 'present'および'absent'。

デフォルト値: 'present'。

##### `instance`

ユーザを管理するSQL Serverインスタンスを指定します。有効なオプション: 既存のインスタンス名を含む文字列。

デフォルト値: 'MSSQLSERVER'。

##### `login`

ユーザをログインに関連付けます。有効なオプション: 既存のログインを含む文字列。指定しない場合、SQL Serverはユーザ名とログインを同一とみなします。

デフォルト値: `undef`。

##### `password`

ユーザにパスワードを割り当てます。データベースの`containment`パラメータが'PARTIAL'に設定されている場合のみ有効です。有効なオプション: 有効なパスワードを指定する文字列。

##### `user`

*必須。*

管理対象のユーザを指定します。有効なオプション: ユーザ名を含む文字列。

デフォルト値: 宣言したリソースのタイトル。

#### `sqlserver::user::permissions`

指定されたデータベース内のユーザカウントに関連付けられるパーミッションを構成します。

親インスタンスにアクセスするために`sqlserver::config`定義タイプが必要です。

##### `database`

*必須。*

ユーザのパーミッションを管理するデータベースを指定します。有効なオプション: 既存のデータベースの名前を含む文字列。

##### `instance`

ユーザとデータベースが存在するSQL Serverインスタンスを指定します。有効なオプション: 既存のインスタンス名を含む文字列。

デフォルト値: 'MSSQLSERVER'。

##### `permissions`

*必須。*

管理対象の1つまたは複数のパーミッションを指定します。有効なオプション: 1つまたは複数の文字列形式の[SQL Serverパーミッション](https://technet.microsoft.com/en-us/library/ms191291%28v=sql.105%29.aspx)を含む配列(例: `['SELECT', 'INSERT', 'UPDATE', 'DELETE']`)。

##### `state`

指定したパーミッションの状態を決定します。有効なオプション: 'GRANT'、'DENY'、'REVOKE'。'REVOKE'に設定すると、Puppetはこれらのパーミッションの明示的ステートメントをすべて削除し、継承されたレベルにフォールバックします。

デフォルト値: 'GRANT'。

##### `user`

*必須。*

パーミッションを管理するユーザを指定します。有効なオプション: ユーザ名を含む文字列。

デフォルト値: 宣言したリソースのタイトル。

##### `with_grant_option`

影響下のユーザがこれらのパーミッションを他者に付与できるかどうかを指定します。有効なオプション: `true`および`false`。

デフォルト値: `false`。

> **SQL Serverにおけるこれらの設定とパーミッションの詳細については、以下を参照してください。**
> 
> * [パーミッション(データベースエンジン)](https://msdn.microsoft.com/en-us/library/ms191291.aspx)
> * [データベースパーミッションを付与する](https://msdn.microsoft.com/en-us/library/ms178569.aspx)

#### `sqlserver::role`

サーバ全体またはデータベース固有のロールを作成および構成します。

親インスタンスにアクセスするために`sqlserver::config`定義タイプが必要です。

##### `authorization`

ロールの所有者を設定します。有効なオプション: 既存のログインまたはユーザ名を含む文字列。 

デフォルト値: 対応する`sqlserver::config`リソースの`user`の値。

##### `database`

ロールを作成するデータベースを指定します。`type`が'DATABASE'に設定されている場合のみ有効です。有効なオプション: 既存のデータベース名を指定する文字列。

デフォルト値: 'master'。

##### `ensure`

管理対象のロールが存在するかどうかを指定します。有効なオプション: 'absent'および'present'。 

デフォルト値: 'present'。

##### `instance`

ロールを管理するSQL Serverインスタンスを指定します。有効なオプション: 既存のインスタンス名を含む文字列。

デフォルト値: 'MSSQLSERVER'。

##### `members`

ロールに1つまたは複数のメンバを割り当てます。有効なオプション: 1つまたは複数のログインおよび/またはユーザ名の配列。

デフォルト値: {}。

##### `members_purge`

`members`パラメータに明示的に含まれていないロールの既存メンバを除外するかどうかを指定します。**注意して使用してください。** `members`が空の配列のときにこのパラメータを`true`に設定した場合、Puppetはすべてのメンバをロールから除外します。有効なオプション: `true`および`false`。

デフォルト値: `false`。

##### `permissions`

*必須。*

1つまたは複数のパーミッションをそのロールに関連付けます。有効なオプション: 1つまたは複数のkey => valueペアのハッシュ値。ここで、各キーは望ましいパーミッション状態で、各値は管理対象のパーミッションを指定する文字列の配列です。

**有効なハッシュキー:**
* 'GRANT'
* 'GRANT_WITH_OPTION' (ユーザがこのパーミッションを他者に付与できる)
* 'DENY'
* 'REVOKE' (このパーミッションの明示的ステートメントをすべて削除し、継承されたレベルにフォールバックする)

**有効なハッシュ値:** [SQL Serverパーミッション](https://technet.microsoft.com/en-us/library/ms191291%28v=sql.105%29.aspx)を含む1つまたは複数の文字列の配列。

**例:** `{'GRANT' => ['CONNECT', 'CREATE ANY DATABASE'] }`

##### `role`

ロールの名前を設定します。有効なオプション: 文字列。インスタンスに対して一意である必要があります。

デフォルト値: 宣言したリソースのタイトル。

##### `type`

ロールを作成するコンテキストを指定します。有効なオプション: 'SERVER'および'DATABASE'。

デフォルト値: 'SERVER'。

#### `sqlserver::role::permissions`

指定されたロールに関連付けられるパーミッションを構成します。

親インスタンスにアクセスするために`sqlserver::config`定義タイプが必要です。

##### `database`

ロールが存在するデータベースを指定します。`type`が'DATABASE'に設定されている場合のみ有効です。有効なオプション: 既存のデータベース名を含む文字列。

デフォルト値: 'master'。

##### `instance`

ロールを管理するSQL Serverインスタンスを指定します。有効なオプション: 既存のインスタンス名を含む文字列。

デフォルト値: 'MSSQLSERVER'。

##### `permissions`

*必須。*

管理対象の1つ又は複数のパーミッションを指定します。有効なオプション: 1つまたは複数の[SQL Serverパーミッション](https://technet.microsoft.com/en-us/library/ms191291%28v=sql.105%29.aspx)(例: 'SELECT'、'INSERT'、'UPDATE'、'DELETE')を含む配列。

##### `role`

*必須。*

パーミッションを管理するロールを指定します。有効なオプション: 既存のロール名を含む文字列。

##### `state`

指定されたパーミッションの状態を指定します。有効なオプション: 'GRANT'、'DENY'、'REVOKE'。'REVOKE'に設定すると、Puppetはこれらのパーミッションの明示的ステートメントをすべて削除し、継承されたレベルにフォールバックします。

デフォルト値: 'GRANT'。

##### `type`

ロールを作成するパーミッションコンテキストを指定します。有効なオプション: 'SERVER'および'DATABASE'。

デフォルト値: 'SERVER'。

##### `with_grant_option`

ロールメンバがこれらのパーミッションを他者に付与できるかどうかを指定します。有効なオプション: `true`および`false` (`true`は`state`が'GRANT'に設定されている場合のみ有効)。

デフォルト値: `false`。

#### `sqlserver::sp_configure`

sp_configure機能を使用して、SQL Serverオプションをアップデートおよび再構成します。部分コンテインメントやファイルストリーム機能を使用するために必要です。

親インスタンスにアクセスするために`sqlserver::config`定義タイプが必要です。

##### `config_name`

sys.configurationsで管理するオプションを指定します。有効なオプション: 構成名を含む文字列。

デフォルト値: 宣言したリソースのタイトル。

##### `instance`

オプションを管理するSQL Serverインスタンスを指定します。有効なオプション: 既存のインスタンス名を含む文字列。

デフォルト値: 'MSSQLSERVER'。

##### `reconfigure`

オプションをアップデートした後にRECONFIGUREを実行するかどうかを指定します。有効なオプション: `true`および`false`。

デフォルト値: `true`。

##### `restart`

オプションをアップデートした後に再起動するようSQL Serverサービスに通知するかどうかを指定します。有効なオプション: `true`および`false`。

デフォルト値: `false`。

##### `value`

*必須。*

指定されたオプションの値を提供します。有効なオプション: 整数値。

##### `with_override`

オプションをアップデートする際に構成値チェックを無効化します。`reconfigure`が`true`に設定されている場合のみ有効です。有効なオプション: `true`および`false`。

デフォルト値: `false`。

> **SQL Serverにおけるこれらの設定の詳細については、以下を参照してください。**
> 
> * [再構成](http://msdn.microsoft.com/en-us/library/ms176069.aspx)
> * [サーバ構成オプション](http://msdn.microsoft.com/en-us/library/ms189631.aspx)

### Microsoft SQL Serverの用語

使用される用語はデータベースシステムごとに若干異なる場合があります。明確な定義については、以下のリストを参照してください。

* **データベース:** 関係性のあるデータテーブルとして整理された情報の集まりとデータオブジェクトの定義。
* **インスタンス:** インストールされ、実行されているデータベースサービス。
* **ログイン:** 1つまたは複数のデータベースへのパーミッションを持つサーバレベルのアカウント。
* **ロール:** データベースレベルまたはサーバレベルのパーミッショングループ。
* **ユーザ:** データベースレベルのアカウント。通常、ログインにマッピングされています。

## 制限事項

本モジュールは、Windows Server 2012または2012 R2のみで使用でき、Puppet Enterprise 3.7以降でのみ動作します。

このモジュールは、指定ホスト上のSQL Serverの単独バージョンのみ管理できます(SQL Server 2012、2014、2016のうちいずれか1つのみ)。このモジュールでは同一バージョンの複数のSQL Serverインスタンスを管理できます。

このモジュールは、SQL Server Native Client SDK (別名SNAC_SDK)を管理できません。SQL ServerのインストールメディアはSDKをインストールできますが、SDKをアンインストールすることはできません。'sqlserver_features' factはSDKの存在を検出します。

## 開発

本モジュールは、PuppetによってPuppet Enterprise (PE)用に設計されました。

本モジュールで問題が発生した場合、またはリクエストしたい機能がある場合、[チケットを送信](https://tickets.puppet.com/browse/MODULES/)してください。

本モジュールの導入時に問題がある場合は、[サポートにお問い合わせ](https://puppet.com/support-services/customer-support)ください。