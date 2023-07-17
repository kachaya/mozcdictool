# 
# Copyright 2023  kachaya
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

#
# 概要：
# Sudachi辞書からmozcのシステム辞書に追加できる辞書ファイルに変換してstdoutに出力
# 
# 準備：
# このスクリプトと同じディレクトリと同じディレクトリに以下のファイルを置く
# ・Sudachi辞書ファイル(core_lex.csv, notcore_lex.csv)
# ・mozc辞書ファイル(dictionary00.txt～dictionary09.txt)
# 
# 実行方法：
# ruby sudachi_converter.rb | sort > mydictioanry.txt
# 

require 'csv'

# sudachiで使用されているunudic-mecab-2.1.2ではleft-id.defとright-id.defは同じ
# 対応するid.defの特定ができない場合は-2を返してあきらめる
SUDACHI_ID_MAP = {
  1 => 1895,      # 1 代名詞,*,*,*,*,*,*,*,和 ⇒ 1895 名詞,代名詞,一般,*,*,*,*
  2 => 1895,      # 2 代名詞,*,*,*,*,*,*,*,混 ⇒ 1895 名詞,代名詞,一般,*,*,*,*
  3 => 1895,      # 3 代名詞,*,*,*,*,*,*,*,漢 ⇒ 1895 名詞,代名詞,一般,*,*,*,*
  
  4 => 12,        # 4 副詞,*,*,*,*,*,*,*,※ ⇒ 12 副詞,一般,*,*,*,*,*
  5 => 12,        # 5 副詞,*,*,*,*,*,*,*,和 ⇒ 12 副詞,一般,*,*,*,*,*
  6 => 12,        # 6 副詞,*,*,*,*,*,*,*,外 ⇒ 12 副詞,一般,*,*,*,*,*
  7 => 12,        # 7 副詞,*,*,*,*,*,*,*,混 ⇒ 12 副詞,一般,*,*,*,*,*
  8 => 12,        # 8 副詞,*,*,*,*,*,*,*,漢 ⇒ 12 副詞,一般,*,*,*,*,*

  380 => 242,     # 380 助動詞,*,*,*,助動詞-マス,終止形-一般,〼,ます,和 ⇒ 242 助動詞,*,*,*,特殊・マス,基本形,まーす

  665 => 284,     # 665 助詞,係助詞,*,*,*,*,も,も,和 ⇒ 284 助詞,係助詞,*,*,*,*,も
  675 => 325,     # 675 助詞,副助詞,*,*,*,*,か,か,和 ⇒ 325 助詞,副助詞／並立助詞／終助詞,*,*,*,*,か
  704 => 314,     # 704 助詞,副助詞,*,*,*,*,まで,まで,和 ⇒ 314 助詞,副助詞,*,*,*,*,まで
  750 => 348,     # 750 助詞,接続助詞,*,*,*,*,て,て,和 ⇒ 348 助詞,接続助詞,*,*,*,*,て
  755 => 349,     # 755 助詞,接続助詞,*,*,*,*,で,で,和 ⇒ 349 助詞,接続助詞,*,*,*,*,で
  758 => 355,     # 758 助詞,接続助詞,*,*,*,*,ながら,ながら,和 ⇒ 355 助詞,接続助詞,*,*,*,*,ながら
  760 => 361,     # 760 助詞,接続助詞,*,*,*,*,ば,ば,和 ⇒ 361 助詞,接続助詞,*,*,*,*,ば
  771 => 368,     # 771 助詞,格助詞,*,*,*,*,から,から,和 ⇒ 368 助詞,格助詞,一般,*,*,*,から
  772 => 369,     # 772 助詞,格助詞,*,*,*,*,が,が,和 ⇒ 369 助詞,格助詞,一般,*,*,*,が
  789 => 370,     # 789 助詞,格助詞,*,*,*,*,で,で,和 ⇒ 370 助詞,格助詞,一般,*,*,*,で
  793 => 371,     # 793 助詞,格助詞,*,*,*,*,と,と,和 ⇒ 371 助詞,格助詞,一般,*,*,*,と
  796 => 372,     # 796 助詞,格助詞,*,*,*,*,に,に,和 ⇒ 372 助詞,格助詞,一般,*,*,*,に
  802 => 374,     # 802 助詞,格助詞,*,*,*,*,の,の,和 ⇒ 374 助詞,格助詞,一般,*,*,*,の
  829 => -2,      # 829 助詞,終助詞,*,*,*,*,*,*,和 ⇒ 助詞,終助詞の最後が'*'のものがないのでスキップ

  4785 => 1916,   # 4785 名詞,固有名詞,一般,*,*,*,*,*,* ⇒ 1916 名詞,固有名詞,一般,*,*,*,*
  4786 => 1916,   # 4786 名詞,固有名詞,一般,*,*,*,*,*,固 ⇒ 1916 名詞,固有名詞,一般,*,*,*,*
  4787 => 1917,   # 4787 名詞,固有名詞,人名,一般,*,*,*,*,* ⇒ 1917 名詞,固有名詞,人名,一般,*,*,*
  4788 => 1917,   # 4788 名詞,固有名詞,人名,一般,*,*,*,*,固 ⇒ 1917 名詞,固有名詞,人名,一般,*,*,*
  4789 => 1918,   # 4789 名詞,固有名詞,人名,名,*,*,*,*,固 ⇒ 1918 名詞,固有名詞,人名,名,*,*,*
  4790 => 1919,   # 4790 名詞,固有名詞,人名,姓,*,*,*,*,固 ⇒ 1919 名詞,固有名詞,人名,姓,*,*,*
  4791 => 1920,   # 4791 名詞,固有名詞,地名,一般,*,*,*,*,* ⇒ 1920 名詞,固有名詞,地域,一般,*,*,*
  4792 => 1920,   # 4792 名詞,固有名詞,地名,一般,*,*,*,*,固 ⇒ 1920 名詞,固有名詞,地域,一般,*,*,*
  4793 => 1920,   # 4793 名詞,固有名詞,地名,国,*,*,*,*,固 ⇒ 1920 名詞,固有名詞,地域,一般,*,*,*

  5129 => 1837,   # 5129 名詞,普通名詞,サ変可能,*,*,*,*,*,* ⇒ 1837 名詞,サ変接続,*,*,*,*,*
  5131 => 1837,   # 5131 名詞,普通名詞,サ変可能,*,*,*,*,*,外 ⇒ 1837 名詞,サ変接続,*,*,*,*,*
  5133 => 1837,   # 5133 名詞,普通名詞,サ変可能,*,*,*,*,*,漢 ⇒ 1837 名詞,サ変接続,*,*,*,*,*
  5135 => 1927,   # 5135 名詞,普通名詞,サ変形状詞可能,*,*,*,*,*,和 ⇒ 1927 名詞,形容動詞語幹,*,*,*,*,*
  5139 => 1847,   # 5139 名詞,普通名詞,一般,*,*,*,*,*,* ⇒ 1847 名詞,一般,*,*,*,*,*
  5142 => 1847,   # 5142 名詞,普通名詞,一般,*,*,*,*,*,和 ⇒ 1847 名詞,一般,*,*,*,*,*
  5144 => 1847,   # 5144 名詞,普通名詞,一般,*,*,*,*,*,外 ⇒ 1847 名詞,一般,*,*,*,*,*
  5145 => 1847,   # 5145 名詞,普通名詞,一般,*,*,*,*,*,混 ⇒ 1847 名詞,一般,*,*,*,*,*
  5146 => 1847,   # 5146 名詞,普通名詞,一般,*,*,*,*,*,漢 ⇒ 1847 名詞,一般,*,*,*,*,*
  5147 => 1847,   # 5147 名詞,普通名詞,一般,*,*,*,*,*,記号 ⇒ 1847 名詞,一般,*,*,*,*,*
  5148 => 1905,   # 5148 名詞,普通名詞,副詞可能,*,*,*,*,*,和 ⇒ 1905 名詞,副詞可能,*,*,*,*,*
  5150 => 1905,   # 5150 名詞,普通名詞,副詞可能,*,*,*,*,*,漢 ⇒ 1905 名詞,副詞可能,*,*,*,*,*
  5151 => 2004,   # 5151 名詞,普通名詞,助数詞可能,*,*,*,*,*,和 ⇒ 2004 名詞,接尾,助数詞,*,*,*,*
  5152 => 2004,   # 5152 名詞,普通名詞,助数詞可能,*,*,*,*,*,外 ⇒ 2004 名詞,接尾,助数詞,*,*,*,*
  5154 => 2004,   # 5154 名詞,普通名詞,助数詞可能,*,*,*,*,*,漢 ⇒ 2004 名詞,接尾,助数詞,*,*,*,*
  5156 => 2021,   # 5156 名詞,普通名詞,形状詞可能,*,*,*,*,*,和 ⇒ 2021 名詞,接尾,形容動詞語幹,*,*,*,*
  5159 => 2021,   # 5159 名詞,普通名詞,形状詞可能,*,*,*,*,*,漢 ⇒ 2021 名詞,接尾,形容動詞語幹,*,*,*,*

  # 「形容詞」これらの連接IDは対応が困難なので使用しているエントリをスキップ
  5160 => -2, 5162 => -2, 5164 => -2, 5166 => -2, 
  5170 => -2, 5172 => -2, 5174 => -2, 5176 => -2, 5178 => -2, 
  5198 => -2, 5324 => -2, 5375 => -2, 5415 => -2,

  # 「動詞」これらの連接IDは対応が困難なので使用しているエントリをスキップ
  131 => -2,
  913 => -2, 915 => -2, 917 => -2, 919 => -2, 921 => -2, 923 => -2, 925 => -2, 927 => -2,
  929 => -2, 931 => -2, 933 => -2, 1286 => -2, 1288 => -2, 1290 => -2, 1292 => -2, 1294 => -2,
  1296 => -2, 1298 => -2, 1300 => -2, 1302 => -2, 1305 => -2, 1317 => -2, 1319 => -2, 1321 => -2,
  1323 => -2, 1325 => -2, 1327 => -2, 1329 => -2, 1331 => -2, 1333 => -2, 1396 => -2, 1399 => -2,
  1402 => -2, 1405 => -2, 1408 => -2, 1411 => -2, 1414 => -2, 1417 => -2, 1421 => -2, 1424 => -2,
  1428 => -2, 1431 => -2, 1434 => -2, 1437 => -2,

  # 「形状詞」＝形容動詞語幹
  5668 => 1927,   # 5668 形状詞,タリ,*,*,*,*,*,*,漢 ⇒ 1927 名詞,形容動詞語幹,*,*,*,*,*
  5669 => 1927,   # 5669 形状詞,一般,*,*,*,*,*,*,和 ⇒ 1927 名詞,形容動詞語幹,*,*,*,*,*

  5687 => 2584,   # 5687 感動詞,一般,*,*,*,*,*,*,* ⇒ 2584 感動詞,*,*,*,*,*,*

  5771 => 1944,   # 5771 接尾辞,名詞的,一般,*,*,*,*,*,和 ⇒ 1944 名詞,接尾,一般,*,*,*,*
  5827 => 1924,   # 5827 接尾辞,名詞的,一般,*,*,*,国,国,漢 ⇒ 1924 名詞,固有名詞,地域,国,*,*,*
  5873 => 2004,   # 5873 接尾辞,名詞的,助数詞,*,*,*,*,*,※ ⇒ 2004 名詞,接尾,助数詞,*,*,*,*

  # TODO: 「動詞接続」か「名詞接続か」、細分化
  5930 => 2586,   # 5930 接続詞,*,*,*,*,*,*,*,和 ⇒ 2586 接続詞,*,*,*,*,*,*
  5931 => 2586,   # 5931 接続詞,*,*,*,*,*,*,*,漢 ⇒ 2586 接続詞,*,*,*,*,*,*

  5932 => 2593,   # 5932 接頭辞,*,*,*,*,*,*,*,和 ⇒ 2593 接頭詞,名詞接続,*,*,*,*,*
  5965 => 2626,   # 5965 接頭辞,*,*,*,*,*,非,非,漢 ⇒ 2626 接頭詞,名詞接続,*,*,*,*,非

  5979 => 2649,   # 5979 連体詞,*,*,*,*,*,*,*,和 ⇒ 2649 連体詞,*,*,*,*,*,*
  5980 => 2649    # 5980 連体詞,*,*,*,*,*,*,*,混 ⇒ 2649 連体詞,*,*,*,*,*,*
}

ORIGINAL = {}

# 重複チェック用
Dir.glob("dictionary*.txt").each do |mozcdict_txt_file|
  CSV.foreach(mozcdict_txt_file, col_sep: "\t", headers: false) do |row|
    # コスト以外を登録
    reading = row[0]
    left_id = row[1]
    right_id = row[2]
    surface = row[4]
    value = [reading, left_id, right_id, surface].join("\t")
    ORIGINAL[value] = true
  end  
end

# 追加用
ADDITIONAL = {}

['core_lex.csv', 'notcore_lex.csv'].each do |sudachi_csv_file|
  CSV.foreach(sudachi_csv_file) do |row|
  # 0 見出し (TRIE 用)
  # 1 左連接ID
  # 2 右連接ID
  # 3 コスト 値を小さくするほど、登録した見出し表記が解析結果として出やすくなります
  # 4 見出し (解析結果表示用)
  # 5 品詞1
  # 6 品詞2
  # 7 品詞3
  # 8 品詞4
  # 9 品詞 (活用型)
  # 10 品詞 (活用形)
  # 11 読み
  # 12 正規化表記
  # 13 辞書形ID
  # 14 分割タイプ
  # 15 A単位分割情報
  # 16 B単位分割情報
  # 17 ※未使用

  # 分割タイプBとCはスキップ
  next if row[14] == 'B'
  next if row[14] == 'C'

  # 変換エンジンに不要なものはスキップ
  next if row[5] == '空白'
  next if row[5] == '記号'
  next if row[5] == '補助記号'
  next if row[6] == '数詞'
  next if row[7] == '地名'
  # next if row[7] == '人名'

  sudachi_left_id = row[1].to_i
  sudachi_right_id = row[2].to_i
  sudachi_cost = row[3].to_i
  sudachi_surface = row[4].gsub(/\\u([\da-fA-F]{4})/) { [$1].pack('H*').unpack('n*').pack('U*') }
  sudachi_reading = row[11]

  # 表記
  # sudachi_surface = sudachi_surface.gsub('’','\'')
  # sudachi_surface = sudachi_surface.gsub('−','-')
  # sudachi_surface = sudachi_surface.gsub('‐','-')
  # 表記がASCII文字のみならばスキップ
  next if sudachi_surface == sudachi_surface.scan(/[\p{ASCII}]/).join
  mozc_surface = sudachi_surface

  # 読み
  # Sudachiの読みに片仮名以外を含むならばスキップ
  next if sudachi_reading =~ /[^\p{Katakana}ー]/

  mozc_reading = sudachi_reading.tr('ァ-ヴ', 'ぁ-ゔ')

  # 連接IDの推定が必要なものはスキップ
  next if sudachi_left_id <= 0
  next if sudachi_right_id <= 0

  # 左連接ID
  mozc_left_id = SUDACHI_ID_MAP[sudachi_left_id]
  if mozc_left_id.nil?
    STDERR.puts "cannot convert left-id:#{sudachi_left_id} #{sudachi_reading} #{sudachi_surface}"
    next
  end
  if mozc_left_id < 0
    STDERR.puts "cannot resolve left-id:#{sudachi_left_id} #{sudachi_reading} #{sudachi_surface}"
    next
  end

  # 右連接ID
  mozc_right_id = SUDACHI_ID_MAP[sudachi_right_id]
  if mozc_right_id.nil?
    STDERR.puts "cannot convert right-id:#{sudachi_right_id} #{sudachi_reading} #{sudachi_surface}"
    next
  end
  if mozc_right_id < 0
    STDERR.puts "cannot resolve right-id:#{sudachi_right_id} #{sudachi_reading} #{sudachi_surface}"
    next
  end

  # 重複チェック
  key = [mozc_reading, mozc_left_id, mozc_right_id, mozc_surface].join("\t")
  if (ADDITIONAL[key])
    # STDERR.puts("dup Sudachi:#{key}")
    next
  end
  # オリジナルとの重複チェック
  if ORIGINAL[key]
    # STDERR.puts("dup Mozc:#{key}")
    next
  end

  ADDITIONAL[key] = true

  cost = sudachi_cost
  cost = 0 if cost < 0
  cost = 19999 if cost >= 20000
  mozc_cost = 6000 + cost / 10

  # output
  puts [mozc_reading, mozc_left_id, mozc_right_id, mozc_cost, mozc_surface].join("\t")

  end
end