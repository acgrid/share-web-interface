object webUIDialog: TwebUIDialog
  Left = 206
  Top = 291
  AlphaBlend = True
  AlphaBlendValue = 233
  BorderStyle = bsDialog
  Caption = 'Share WebUI'
  ClientHeight = 395
  ClientWidth = 679
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'MS PGothic'
  Font.Style = []
  OldCreateOrder = False
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 12
  object btnApply: TButton
    Left = 40
    Top = 360
    Width = 75
    Height = 25
    Caption = '&Apply'
    Default = True
    TabOrder = 0
    OnClick = btnApplyClick
  end
  object grpCfg: TGroupBox
    Left = 8
    Top = 8
    Width = 249
    Height = 161
    Caption = 'Configuration'
    TabOrder = 1
    object cfgTemplate: TLabeledEdit
      Left = 112
      Top = 64
      Width = 121
      Height = 20
      EditLabel.Width = 72
      EditLabel.Height = 12
      EditLabel.Caption = 'Web &Template'
      LabelPosition = lpLeft
      LabelSpacing = 10
      TabOrder = 0
      Text = 'template.html'
    end
    object cfgUser: TLabeledEdit
      Left = 112
      Top = 88
      Width = 121
      Height = 20
      EditLabel.Width = 84
      EditLabel.Height = 12
      EditLabel.Caption = 'HTTP &Username'
      LabelPosition = lpLeft
      LabelSpacing = 10
      TabOrder = 1
      Text = 'admin'
    end
    object cfgPass: TLabeledEdit
      Left = 112
      Top = 112
      Width = 121
      Height = 20
      EditLabel.Width = 82
      EditLabel.Height = 12
      EditLabel.Caption = 'HTTP Pa&ssword'
      LabelPosition = lpLeft
      LabelSpacing = 10
      TabOrder = 2
      Text = 'admin'
    end
    object cfgAuthTitle: TLabeledEdit
      Left = 112
      Top = 40
      Width = 121
      Height = 20
      EditLabel.Width = 92
      EditLabel.Height = 12
      EditLabel.Caption = 'HTTP &Realm Title'
      LabelPosition = lpLeft
      LabelSpacing = 10
      TabOrder = 3
      Text = 'Share WebUI'
    end
    object cfgSuperPass: TLabeledEdit
      Left = 112
      Top = 133
      Width = 121
      Height = 20
      EditLabel.Width = 85
      EditLabel.Height = 12
      EditLabel.Caption = 'Ad&min Password'
      LabelPosition = lpLeft
      LabelSpacing = 10
      TabOrder = 4
      Text = #9320
    end
    object cfgSrvTitle: TLabeledEdit
      Left = 112
      Top = 16
      Width = 121
      Height = 20
      EditLabel.Width = 85
      EditLabel.Height = 12
      EditLabel.Caption = 'Server Si&gnature'
      LabelPosition = lpLeft
      LabelSpacing = 10
      TabOrder = 5
      Text = 'Share WebUI plugin 1.1'
    end
  end
  object accesslog: TListView
    Left = 264
    Top = 8
    Width = 409
    Height = 137
    Columns = <
      item
        Caption = 'IP Address'
        MinWidth = 100
        Width = 100
      end
      item
        Caption = 'Login'
        MaxWidth = 40
        Width = 40
      end
      item
        Alignment = taRightJustify
        Caption = 'Access'
      end
      item
        Caption = 'Page'
        Width = 40
      end
      item
        Caption = 'File'
        Width = 40
      end
      item
        Caption = 'Auth'
        Width = 40
      end
      item
        Caption = 'Last Activity'
        MinWidth = 80
        Width = 90
      end>
    GridLines = True
    ReadOnly = True
    RowSelect = True
    SortType = stText
    TabOrder = 2
    ViewStyle = vsReport
  end
  object log: TTntMemo
    Left = 264
    Top = 152
    Width = 409
    Height = 233
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 3
    WordWrap = False
  end
  object GrpBindings: TGroupBox
    Left = 8
    Top = 176
    Width = 249
    Height = 177
    Caption = '&Bindings'
    TabOrder = 4
    object cfgPort: TLabeledEdit
      Left = 128
      Top = 64
      Width = 49
      Height = 20
      EditLabel.Width = 104
      EditLabel.Height = 12
      EditLabel.Caption = 'HTTP Listening &Port'
      LabelPosition = lpLeft
      LabelSpacing = 10
      TabOrder = 0
      Text = '23300'
      OnChange = cfgPortChange
      OnKeyPress = cfgPortKeyPress
    end
    object cfgBind4: TLabeledEdit
      Left = 112
      Top = 16
      Width = 121
      Height = 20
      EditLabel.Width = 95
      EditLabel.Height = 12
      EditLabel.Caption = 'IPv&4 Bind Address'
      LabelPosition = lpLeft
      LabelSpacing = 10
      TabOrder = 1
      Text = '0.0.0.0'
    end
    object cfgBind6: TLabeledEdit
      Left = 112
      Top = 40
      Width = 121
      Height = 20
      EditLabel.Width = 95
      EditLabel.Height = 12
      EditLabel.Caption = 'IPv&6 Bind Address'
      LabelPosition = lpLeft
      LabelSpacing = 10
      TabOrder = 2
      Text = '::'
    end
    object cfgSPort: TLabeledEdit
      Left = 128
      Top = 88
      Width = 49
      Height = 20
      EditLabel.Width = 111
      EditLabel.Height = 12
      EditLabel.Caption = 'HTTPS Listening P&ort'
      LabelPosition = lpLeft
      LabelSpacing = 10
      TabOrder = 3
      Text = '23333'
      OnChange = cfgSPortChange
      OnKeyPress = cfgPortKeyPress
    end
    object cfgSSLCert: TLabeledEdit
      Left = 13
      Top = 125
      Width = 108
      Height = 20
      EditLabel.Width = 78
      EditLabel.Height = 12
      EditLabel.Caption = 'SSL &Certificate'
      TabOrder = 4
      Text = 'sslcert.crt'
    end
    object cfgSSLKey: TLabeledEdit
      Left = 128
      Top = 125
      Width = 105
      Height = 20
      EditLabel.Width = 66
      EditLabel.Height = 12
      EditLabel.Caption = 'SSL &Key File'
      TabOrder = 5
      Text = 'sslcert.key'
    end
    object cfgSSLPrivateKey: TLabeledEdit
      Left = 112
      Top = 152
      Width = 121
      Height = 20
      EditLabel.Width = 73
      EditLabel.Height = 12
      EditLabel.Caption = 'SSL Pass&word'
      LabelPosition = lpLeft
      LabelSpacing = 10
      PasswordChar = '*'
      TabOrder = 6
    end
    object ChkHTTPS: TCheckBox
      Left = 184
      Top = 88
      Width = 57
      Height = 17
      Caption = 'E&nable'
      TabOrder = 7
    end
  end
  object BtnRestart: TButton
    Left = 128
    Top = 360
    Width = 105
    Height = 25
    Caption = 'Restart &Listening'
    TabOrder = 5
    OnClick = BtnRestartClick
  end
  object httpd: TIdHTTPServer
    Bindings = <>
    DefaultPort = 23300
    OnConnect = httpdConnect
    ServerSoftware = 'Share WebUI Plugin'
    OnCommandGet = httpdCommandGet
    Left = 368
  end
  object AddTrigDelay: TTimer
    Enabled = False
    Interval = 1
    OnTimer = AddTrigDelayTimer
    Left = 368
    Top = 216
  end
  object AddQueryDelay: TTimer
    Enabled = False
    Interval = 1
    OnTimer = AddQueryDelayTimer
    Left = 368
    Top = 296
  end
  object DelQueryDelay: TTimer
    Enabled = False
    Interval = 1
    OnTimer = DelQueryDelayTimer
    Left = 400
    Top = 296
  end
  object DeleteFilterDelay: TTimer
    Enabled = False
    Interval = 1
    OnTimer = DeleteFilterDelayTimer
    Left = 400
    Top = 240
  end
  object AddFilterDelay: TTimer
    Enabled = False
    Interval = 1
    OnTimer = AddFilterDelayTimer
    Left = 368
    Top = 240
  end
  object AddDirDelay: TTimer
    Enabled = False
    Interval = 1
    OnTimer = AddDirDelayTimer
    Left = 368
    Top = 264
  end
  object DeleteDirDelay: TTimer
    Enabled = False
    Interval = 1
    OnTimer = DeleteDirDelayTimer
    Left = 400
    Top = 264
  end
  object DBCONN: TADOConnection
    ConnectionString = 
      'Provider=Microsoft.Jet.OLEDB.4.0;Data Source=WebUIBBS_yx3d4q16a.' +
      'mdb;Persist Security Info=False'
    Provider = 'Microsoft.Jet.OLEDB.4.0'
    Left = 336
  end
  object DBDS: TADODataSet
    Connection = DBCONN
    Parameters = <>
    Left = 336
    Top = 24
  end
  object QueryReqHandler: TTimer
    Interval = 1
    OnTimer = QueryReqHandlerTimer
    Left = 368
    Top = 184
  end
  object sslhandler: TIdServerIOHandlerSSLOpenSSL
    SSLOptions.RootCertFile = 'sslcert.crt'
    SSLOptions.CertFile = 'sslcert.crt'
    SSLOptions.KeyFile = 'sslkey.key'
    SSLOptions.Method = sslvSSLv23
    SSLOptions.SSLVersions = [sslvSSLv2, sslvSSLv3, sslvTLSv1]
    SSLOptions.Mode = sslmBoth
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    OnGetPassword = sslhandlerGetPassword
    Left = 432
  end
  object httpsd: TIdHTTPServer
    Bindings = <>
    IOHandler = sslhandler
    OnConnect = httpdConnect
    ServerSoftware = 'Share WebUI Plugin'
    OnCommandGet = httpdCommandGet
    Left = 400
  end
  object StartupDelay: TTimer
    Enabled = False
    Interval = 2330
    OnTimer = StartupDelayTimer
    Left = 368
    Top = 152
  end
end
