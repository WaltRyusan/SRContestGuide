import 'package:sr_contest_guide/importer.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with RouteAware {
  // 編集モードフラグの初期値設定
  bool is_editing = false;
  // 編集ボタン押下時の選択したアイテム
  Set<String> edit_selected_items = {};
  // 保存されたリストのタイトル
  List<String> saved_titles = [];
  // 音声出力するテキスト
  Map<String, String> wave_texts = {};

  //バナー広告の読み込みと初期化
  BannerAd? _banner_ad;

  // 画面読み込み時の処理
  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // Ads:バナー広告の初期化
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _banner_ad = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面遷移検知のために必要
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // 画面遷移検知
    routeObserver.unsubscribe(this);
    // 広告の解放
    _banner_ad?.dispose();
    super.dispose();
  }

  // 一度、別の画面に遷移したあとで、再度この画面に戻ってきた時にコールされる
  @override
  void didPopNext() {
    setState(() {
      _load_saved_titles;
    });
  }

  Map<int, String> _convert_wave_texts(Map<String, String> wave_texts) {
    return wave_texts.map((key, value) => MapEntry(int.parse(key), value));
  }

  Future<List<String>> _load_saved_titles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? titles = prefs.getStringList('savedTitles');
    if (titles != null) {
      debugPrint("読み込んだリストのタイトル一覧: $titles");
      return titles;
    } else {
      debugPrint("保存されたリストはありません。");
      return []; // nullではなく空のリストを返す
    }
  }

  //　画面遷移する際に選択したタイトルの中身をWaveListViewに渡す
  Future<void> _show_wave_list_view(String title) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? wave_texts_json = prefs.getString(title);

    // wave_texts_jsonがnullでないことをチェック
    if (wave_texts_json != null) {
      // wave_texts_jsonがnullでない場合の処理
      // wave_texts_jsonをデコードする前にnullでないことを確認
      Map<String, dynamic>? wave_texts_decoded = jsonDecode(wave_texts_json);

      if (wave_texts_decoded != null) {
        // wave_texts_decodedをMap<String, String>に変換
        Map<String, String> wave_texts = wave_texts_decoded.map((key, value) =>
            MapEntry<String, String>(key.toString(), value.toString()));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WaveListView(
              initialTitle: title,
              initialWaveTexts: _convert_wave_texts(wave_texts),
            ),
          ),
        );
      } else {
        // wave_texts_decodedがnullの場合のエラーハンドリング
        debugPrint('Failed to decode wave_texts_json.');
      }
    } else {
      // wave_texts_jsonがnullの場合のエラーハンドリング
      debugPrint('wave_texts_json is null.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: is_editing
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              is_editing = false;
              edit_selected_items.clear();
            });
          },
        )
            : IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            setState(() {
              is_editing = true;
            });
          },
        ),
        title: const Text(
          "指示リスト",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (is_editing)
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.primary),
              onPressed: edit_selected_items.isNotEmpty
                  ? () async {
                SharedPreferences prefs =
                await SharedPreferences.getInstance();
                List<String>? titles = prefs.getStringList('savedTitles');
                if (titles != null) {
                  for (String item in edit_selected_items) {
                    // SharedPreferencesから選択されたタイトルを削除
                    prefs.remove(item);
                  }
                }
                // saved_titlesリストから選択されたタイトルを削除
                setState(() {
                  saved_titles.removeWhere(
                          (item) => edit_selected_items.contains(item));
                  edit_selected_items.clear();
                });
                // 保存されたタイトルリストを更新
                await prefs.setStringList('savedTitles', saved_titles);
              }
                  : null,
            )
          else
            IconButton(
              icon: const Icon(Icons.info_sharp), //TODO: ver2.0.0で設定画面の対応
              onPressed: () {
                // 編集モードを終了する
                setState(() {
                  is_editing = false;
                  edit_selected_items.clear(); // すべての選択を解除する
                });
                // 設定画面に遷移 TODO: ver2.0.0で対応
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsView()),
                );

              },
            ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _load_saved_titles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // データの読み込み中はローディング表示などを行う
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            // エラーが発生した場合の処理
            return Text('リストの読み込みに失敗しました: ${snapshot.error}');
          } else {
            // データを正常に取得した場合の処理
            saved_titles = snapshot.data ?? [];
            if (saved_titles.isNotEmpty) {
              // タイトルが存在する場合はリストビューで表示
              return ListView.builder(
                itemCount: saved_titles.length,
                itemBuilder: (context, index) {
                  final String title = saved_titles[index];
                  final bool is_selected = edit_selected_items.contains(title);

                  return ListTile(
                    leading: is_editing
                        ? Checkbox(
                      value: is_selected,
                      onChanged: (newValue) {
                        setState(() {
                          if (newValue != null && newValue) {
                            edit_selected_items.add(title);
                          } else {
                            edit_selected_items.remove(title);
                          }
                        });
                      },
                    )
                        : null,
                    title: Text(title),
                    // タップしたときの処理を記述
                    onTap: () {
                      if (!is_editing) {
                        // タイトルに対応するWaveListViewに遷移するなどの処理を行う
                        _show_wave_list_view(title);
                      }
                    },
                    selected: is_selected,
                  );
                },
              );
            } else {
              // タイトルが存在しない場合の処理
              return Column(
                mainAxisAlignment: MainAxisAlignment.start, // 上端に配置
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Text(
                      '保存されたリストはありません。\n[＋]ボタンをタップして追加してください。',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(

        onPressed: () {
          // 編集モードを終了する
          setState(() {
            is_editing = false;
            edit_selected_items.clear(); // すべての選択を解除する
          });
          // WaveListViewに遷移
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WaveListView(
                initialTitle: DateUtil.formattedToday(saved_titles),
                initialWaveTexts: null, // 追加ボタン押下時がwave_textsは存在しない
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: _banner_ad != null
          ? Container(
        height: 60,
        child: AdWidget(ad: _banner_ad!),
      )
          : null,
    );
  }
}