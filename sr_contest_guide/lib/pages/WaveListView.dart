import 'package:sr_contest_guide/importer.dart';

class WaveListView extends StatefulWidget {
  final String initialTitle;
  final Map<int, String>? initialWaveTexts;

  const WaveListView({
    Key? key,
    required this.initialTitle,
    this.initialWaveTexts,
  }) : super(key: key);

  @override
  _WaveListViewState createState() => _WaveListViewState();
}

class _WaveListViewState extends State<WaveListView> {
  // TTS
  FlutterTts flutterTts = FlutterTts();

  // テキストフィールドコントローラー
  Map<int, TextEditingController> waveTextsControllers = {};

  // タイトル
  final TextEditingController _titleController = TextEditingController();

  // データ
  Map<int, String> waveTexts = {};

  // 状態
  String title = "";
  bool isPlaying = false;
  bool isWave1Expanded = false;
  bool isWave2Expanded = false;
  bool isWave3Expanded = false;
  bool isWave4Expanded = false;
  bool isWave5Expanded = false;

  // AdsMob（リストに複数表示する）
  List<BannerAd?> _banner_ads = List.generate(6, (_) => null);
  BannerAd? _banner_ad;
  InterstitialAd? _interstitialAd;

  // 現在の再生中のWave
  int currentWave = 1;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle;
    _initializeTts(); // TTS設定
    _initList();

    // Ads: 広告の初期化
    // _loadBannerAd();
    _loadBannerAds();
    _loadInterstitialAd();
  }

  // void _loadBannerAd() {
  //   // Ads:バナー広告の初期化
  //   BannerAd(
  //     adUnitId: AdHelper.bannerAdUnitId,
  //     request: AdRequest(),
  //     size: AdSize.banner,
  //     listener: BannerAdListener(
  //       onAdLoaded: (ad) {
  //         setState(() {
  //           _banner_ad = ad as BannerAd;
  //         });
  //       },
  //       onAdFailedToLoad: (ad, err) {
  //         kDebugModePrint('Failed to load a banner ad: ${err.message}');
  //         ad.dispose();
  //       },
  //     ),
  //   ).load();
  // }

  void _loadBannerAds() {
    for (int i = 0; i < 6; i++) {
      BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _banner_ads[i] = ad as BannerAd;
            });
          },
          onAdFailedToLoad: (ad, err) {
            kDebugModePrint('Failed to load a banner ad: ${err.message}');
            ad.dispose();
          },
        ),
      ).load();
    }
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          kDebugModePrint('Failed to load interstitial ad: ${error.message}');
        },
      ),
    );
  }

  // 画面が表示される度に表示される
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      // 保存済みリストを呼び出す
      _loadData(); // データをロード
    }
  }

  void _initList() {
    // 初期タイトルを設定(選択したリスト名 or 初期値の日付)
    _titleController.text = widget.initialTitle;

    // waveTexts が null でなければ widget.waveTexts の値が使われ、null であれば空のマップが初期値として使用される
    waveTexts = widget.initialWaveTexts ?? {};

    // waveTextsControllers を初期化
    for (int i = 0; i < 500; i++) {
      // waveTextsControllers[i] = TextEditingController();
      // waveTexts[i] = ''; // デフォルトで空の文字列を設定
      waveTextsControllers[i] = TextEditingController(text: waveTexts[i] ?? '');
    }
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? loadedText = prefs.getString(widget.initialTitle);
    if (loadedText != null) {
      Map<String, dynamic> decodedData = jsonDecode(loadedText);
      Map<int, String> loadedWaveTexts = {};
      decodedData.forEach((key, value) {
        loadedWaveTexts[int.parse(key)] = value.toString();
      });
      setState(() {
        _titleController.text = widget.initialTitle;
        waveTexts = loadedWaveTexts;
      });
    }
  }

  // 戻るボタンタップ時の挙動
  Future<void> _saveDataAndBackView({bool backView = false}) async {
    // テキスト有無の判定フラグ
    bool hasText = false;

    // waveTexts マップを更新
    for (int i = 0; i < 500; i++) {
      waveTexts[i] = waveTextsControllers[i]?.text ?? ''; // null の場合は空文字を設定
      if (waveTexts[i]!.isNotEmpty) {
        hasText = true;
      }
    }

    // テキストがある場合に保存処理を行う
    if (hasText) {
      // SharedPreferences(ローカルストレージ)に保存
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // waveTextsをJSON形式に変換（エンコード）
      Map<String, String> waveTextsStringKeys = {};
      waveTexts.forEach((key, value) {
        waveTextsStringKeys[key.toString()] = value;
      });
      // waveTextsをJSON形式に変換（エンコード）
      String waveTextsJson = jsonEncode(waveTextsStringKeys);
      await prefs.setString(widget.initialTitle, waveTextsJson);
      kDebugModePrint('waveTexts マップのタイトル: ${widget.initialTitle}');
      kDebugModePrint('waveTexts マップの内容: $waveTexts');

      // 保存したタイトルを保存済みリストに追加
      List<String>? savedTitles = prefs.getStringList('savedTitles') ?? [];
      if (!savedTitles.contains(widget.initialTitle)) {
        savedTitles.add(widget.initialTitle);
        await prefs.setStringList('savedTitles', savedTitles);
      }
    }

    if (backView) {
      // 画面を閉じて前の画面に戻る
      Navigator.pop(context);
    }
  }


  @override
  void dispose() {
    _titleController.dispose(); // メモリリークを防ぐために破棄
    waveTextsControllers.values.forEach((controller) => controller.dispose());

    //Ads: 広告関連のdispose
    // _banner_ad?.dispose();
    _banner_ads.forEach((ad) => ad?.dispose());
    _interstitialAd?.dispose();
    super.dispose();
  }

  // tts(Text to Speech)の初期設定
  void _initializeTts() async {
    await flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker]);
    await flutterTts.setPitch(0.8); // 読み上げる声の高さ
    await flutterTts.setSpeechRate(0.5); // 読み上げ速度
    await flutterTts.setLanguage("ja-JP"); // 読み上げ言語
    await flutterTts.setVolume(1.0); // 読み上げる音声のボリューム
  }

  // 再生ボタンタップ時の挙動
  void startPlayback() async {
    setState(() {
      isPlaying = true;
    });

    _speakText('ガイドをスタートします');
    //再生ボタンを押下してから開始するまでの時間
    await Future.delayed(Duration(seconds: 15));

    // テキストフィールド全てを再生
    for (int wave = 1; wave <= 5; wave++) {

      // currentWave = wave;
      for (int index = 1; index <= 100; index++) {
        String? tts_text = waveTexts[index - 1 + (wave - 1) * 100];

        kDebugModePrint('Wave$wave　$index秒 出力音声「$tts_text」'); // テキストとindexを出力

        // テキストが空でない場合のみ喋らせる
        if (tts_text != null && tts_text.isNotEmpty) {
          await _speakText(tts_text);
        } else {
          await Future.delayed(Duration(seconds: 1));
        }

        // 再生中ではない場合、ループを抜ける
        if (!isPlaying) {
          break;
        }
      }

      await Future.delayed(Duration(seconds: 1));

      // waveの間のインターバル（前waveから終わって次wave開始まで）
      if (wave < 5 && isPlaying) {
        await Future.delayed(Duration(seconds: 19));
      }

      // 再生中ではない場合、ループを抜ける
      if (!isPlaying) {
        break;
      }
    }

    // 再生が終了した場合、停止する
    setState(() {
      isPlaying = false;
    });
    if (kDebugMode) {
      kDebugModePrint('再生処理が完了しました。');

      // 音声の読み上げが完了したら、インタースティシャル広告を表示
      if (_interstitialAd != null) {
        await _interstitialAd!.show();
        _interstitialAd = null;
        _loadInterstitialAd(); // 次の広告のロードを開始
      }

    }
  }

  Future<void> _speakText(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _showInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd(); // 次の広告のロードを開始
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true, // floatingbutoonを動かすか否か（defaultがtrue）
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                _saveDataAndBackView(backView: true);
              },
            ),
            centerTitle: true,
            title: TextField(
            controller: _titleController,
              decoration: InputDecoration(
                hintText: 'タイトルを入力してください。',
                border: InputBorder.none, // アンダーバーを非表示
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              onSubmitted: (value) {
                // ユーザが編集を終了したときにタイトルを更新
                setState(() {
                  title = value;
                });
              },
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    //TODO ver2.0.0 セクションには選択式で潮・環境を設定してTTSさせる
                    sectionView("Wave 1", isWave1Expanded, 0),
                    sectionView("Wave 2", isWave2Expanded, 1),
                    sectionView("Wave 3", isWave3Expanded, 2),
                    sectionView("Wave 4", isWave4Expanded, 3),
                    sectionView("Wave 5", isWave5Expanded, 4),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation
              .centerFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () { // 再生ボタン押下時
              // テキストフィールドに値があるかどうかをチェック
              bool hasText = false;
              for (int i = 0; i < 5; i++) {
                for (int j = 0; j < 100; j++) {
                  if (waveTexts[j + i * 100] != null &&
                      waveTexts[j + i * 100]!.isNotEmpty) {
                    hasText = true;
                    break;
                  }
                }
                if (hasText) {
                  break;
                }
              }

              if (!hasText) {
                // テキストがない場合、エラーメッセージを表示
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('指示テキストを入力してください。'),
                  ),
                );
              } else {
                if (isPlaying) {
                  // 再生中は停止アイコンを表示し、再生を停止する処理を実行
                  setState(() {
                    kDebugModePrint('再生を停止しました。');
                    isPlaying = false;
                  });
                } else {
                  _saveDataAndBackView();
                  // 再生中でなければ再生アイコンを表示し、再生を開始する処理を実行
                  kDebugModePrint('再生を開始しました。');
                  startPlayback();
                }
              }
            },
            // backgroundColor: Colors.deepOrange,
            child: isPlaying ? const Icon(Icons.stop) : const Icon(
                Icons.play_arrow),
          ),
          // bottomNavigationBar: _banner_ad != null // 単体
          bottomNavigationBar: _banner_ads[5] != null // 複数
              ? SizedBox(
            height: 60,
            // child: AdWidget(ad: _banner_ad!),
            child: AdWidget(ad: _banner_ads[5]!),
          )
              : Container(
            height: 60,
          ),
        )
    );
  }

  Widget sectionView(String header, bool isExpanded, int waveIndex) {
    final List<FocusNode> focusNodes = List.generate(100, (_) => FocusNode());

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // セクションヘッダータップ時にテキストフィールドのフォーカスを外す
            FocusScope.of(context).unfocus();
            // セクションタブ開閉の管理
            setState(() {
              switch (waveIndex) {
                case 0:
                  isWave1Expanded = !isWave1Expanded;
                  break;
                case 1:
                  isWave2Expanded = !isWave2Expanded;
                  break;
                case 2:
                  isWave3Expanded = !isWave3Expanded;
                  break;
                case 3:
                  isWave4Expanded = !isWave4Expanded;
                  break;
                case 4:
                  isWave5Expanded = !isWave5Expanded;
                  break;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 16, 0, 16),
            color: Colors.deepOrange,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  header,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Icon(
                  isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        if (!isExpanded)
          const Divider(
            height: 0.01,
            color: Colors.black45,
          ),
        if (isExpanded)
          ...List.generate(
            // 101,
            100,
            (index) {
                  // 101個目にバナー広告を表示
              if (index == 100) {
                return SizedBox(
                  height: 75,
                  // child: AdWidget(ad: _banner_ad!),
                  child: _banner_ads[waveIndex] != null ? AdWidget(ad: _banner_ads[waveIndex]!) : Container(),
                );
              } else {
                final int textFieldIndex = index + waveIndex * 100;
                final FocusNode focusNode = focusNodes[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 8),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text("${100 - index} 秒"),
                      ),
                      Expanded(
                        flex: 6,

                        child: TextField(
                        focusNode: focusNode,
                          onTap: () {
                            setState(() {
                              for (var node in focusNodes) {
                                if (node != focusNode) {
                                  node.unfocus();
                                }
                              }
                              // for (var node in focusNodes) {
                              //   node.unfocus();
                              // }
                              // focusNode.requestFocus();
                            });
                          },
                          onChanged: (value) {
                            setState(() {
                              waveTexts[index + waveIndex * 100] = value;
                            });
                          },
                          controller: waveTextsControllers[index +
                              waveIndex * 100],
                          decoration: InputDecoration(
                            hintText: "",
                            suffixIcon: waveTextsControllers[index +
                                waveIndex * 100]!.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  waveTextsControllers[index + waveIndex * 100]!
                                      .clear();
                                });
                              },
                            )
                                : null,
                            border: const OutlineInputBorder(),
                          ),
                          onEditingComplete: () {
                            // 現在のコントローラを取得
                            var controller = waveTextsControllers[index + waveIndex * 100];

                            // 文字列が空の場合のみクリアする
                            if(controller!.text.isEmpty){
                              controller.text = "";
                            } else {
                              controller.text = controller.text;
                            }

                            // if (textFieldIndex < 499) {
                            //   focusNode.unfocus();
                              FocusScope.of(context).requestFocus(
                                  focusNodes[index + 1]);
                            // }
                            // else {
                            //   focusNode.unfocus();
                            // }
                          },
                          // // キーボードの確定ボタンタップ時アクション：次のテキストフィールドへフォーカス移動
                          // textInputAction: TextInputAction.next,
                        ),

                      ),
                    ],
                  ),

                );
              }
            },
          ),
      ],
    );
  }
}
