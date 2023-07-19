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
# このスクリプトと同じディレクトリに以下のファイルを置く
# ・Sudachi辞書ファイル(core_lex.csv, notcore_lex.csv)
# ・mozc辞書ファイル(dictionary00.txt～dictionary09.txt)
# 
# 実行方法：
# ruby sudachi_converter.rb | sort > mydictioanry.txt
# 

require 'csv'

# sudachiで使用されているunudic-mecab-2.1.2ではleft-id.defとright-id.defは同じ
SUDACHI_ID_MAP = {
  1 => 1895,      # 1 代名詞,*,*,*,*,*,*,*,和 ⇒ 1895 名詞,代名詞,一般,*,*,*,*
  2 => 1895,      # 2 代名詞,*,*,*,*,*,*,*,混 ⇒ 1895 名詞,代名詞,一般,*,*,*,*
  3 => 1895,      # 3 代名詞,*,*,*,*,*,*,*,漢 ⇒ 1895 名詞,代名詞,一般,*,*,*,*
  
  4 => 12,        # 4 副詞,*,*,*,*,*,*,*,※ ⇒ 12 副詞,一般,*,*,*,*,*
  5 => 12,        # 5 副詞,*,*,*,*,*,*,*,和 ⇒ 12 副詞,一般,*,*,*,*,*
  6 => 12,        # 6 副詞,*,*,*,*,*,*,*,外 ⇒ 12 副詞,一般,*,*,*,*,*
  7 => 12,        # 7 副詞,*,*,*,*,*,*,*,混 ⇒ 12 副詞,一般,*,*,*,*,*
  8 => 12,        # 8 副詞,*,*,*,*,*,*,*,漢 ⇒ 12 副詞,一般,*,*,*,*,*

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

  5668 => 1927,   # 5668 形状詞,タリ,*,*,*,*,*,*,漢 ⇒ 1927 名詞,形容動詞語幹,*,*,*,*,*
  5669 => 1927,   # 5669 形状詞,一般,*,*,*,*,*,*,和 ⇒ 1927 名詞,形容動詞語幹,*,*,*,*,*

  5687 => 2584,   # 5687 感動詞,一般,*,*,*,*,*,*,* ⇒ 2584 感動詞,*,*,*,*,*,*

  5771 => 1944,   # 5771 接尾辞,名詞的,一般,*,*,*,*,*,和 ⇒ 1944 名詞,接尾,一般,*,*,*,*
  5873 => 2004,   # 5873 接尾辞,名詞的,助数詞,*,*,*,*,*,※ ⇒ 2004 名詞,接尾,助数詞,*,*,*,*

  5932 => 2593,   # 5932 接頭辞,*,*,*,*,*,*,*,和 ⇒ 2593 接頭詞,名詞接続,*,*,*,*,*

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

  # 変換エンジンに不要なものはスキップ
  next if row[5] == '空白'
  next if row[5] == '記号'
  next if row[5] == '補助記号'
  next if row[6] == '数詞'
  next if row[7] == '地名'

  sudachi_left_id = row[1].to_i
  sudachi_right_id = row[2].to_i
  sudachi_cost = row[3].to_i
  sudachi_surface = row[4].gsub(/\\u([\da-fA-F]{4})/) { [$1].pack('H*').unpack('n*').pack('U*') }
  sudachi_reading = row[11]

  # 連接IDの推定が必要なものはスキップ
  next if sudachi_left_id <= 0
  next if sudachi_right_id <= 0

  # 読み
  # Sudachiの読みに片仮名以外を含むならばスキップ
  next if sudachi_reading =~ /[^\p{Katakana}ー]/

  mozc_reading = sudachi_reading.tr('ァ-ヴ', 'ぁ-ゔ')

  # 表記
  # 表記がASCII文字のみならばスキップ
  next if sudachi_surface == sudachi_surface.scan(/[\p{ASCII}]/).join

  # 単語でなければスキップ
  if sudachi_surface =~ /[^[\-_&.0-9A-Za-z]\p{Hiragana}\p{Katakana}ー\p{Han}]/
    # STDERR.puts "non-word:#{sudachi_surface}"
    next
  end

  mozc_surface = sudachi_surface

  if row[14] == 'A'
    # 左連接ID
    mozc_left_id = SUDACHI_ID_MAP[sudachi_left_id]
    if mozc_left_id.nil?
      STDERR.puts "cannot convert left-id:#{sudachi_left_id} #{sudachi_reading} #{sudachi_surface}"
      next
    end
    # 右連接ID
    mozc_right_id = SUDACHI_ID_MAP[sudachi_right_id]
    if mozc_right_id.nil?
      STDERR.puts "cannot convert right-id:#{sudachi_right_id} #{sudachi_reading} #{sudachi_surface}"
      next
    end
  elsif row[14] == 'B'
    next
  elsif row[14] == 'C'
    mozc_left_id = -1
    mozc_right_id = -1
    # 品詞情報から連接IDを導き出す
    if row[5] == '名詞'
      if row[6] == '普通名詞'
        if row[7] == '一般'
          mozc_left_id = mozc_right_id = 1847 # 名詞,一般,*,*,*,*,*
        elsif row[7] == 'サ変可能'
          mozc_left_id = mozc_right_id = 1837 # 名詞,サ変接続,*,*,*,*,*
        elsif row[7] == '形状詞可能'
          mozc_left_id = mozc_right_id = 1927 # 名詞,形容動詞語幹,*,*,*,*,*
        elsif row[7] == '副詞可能'
          mozc_left_id = mozc_right_id = 1905 # 名詞,副詞可能,*,*,*,*,*
        elsif row[7] == '助数詞可能'
          mozc_left_id = mozc_right_id = 2004 # 名詞,接尾,助数詞,*,*,*,*
        end
      elsif row[6] == '固有名詞'
        if row[7] == '一般'
          mozc_left_id = mozc_right_id = 1916 # 名詞,固有名詞,一般,*,*,*,*
        elsif row[7] == '人名'
          mozc_left_id = mozc_right_id = 1917 # 名詞,固有名詞,人名,一般,*,*,*
        end
      end
    elsif row[5] == '形状詞'
      if row[6] == '一般'
        mozc_left_id = mozc_right_id = 1927 # 名詞,形容動詞語幹,*,*,*,*,*
      end
    elsif row[5] == '副詞'
      mozc_left_id = mozc_right_id = 12 # 副詞,一般,*,*,*,*,*
    elsif row[5] == '感動詞'
      mozc_left_id = mozc_right_id = 2584 # 感動詞,*,*,*,*,*,*
    end

    if mozc_left_id < 0 || mozc_right_id < 0
      STDERR.puts row.join(",") 
      next
    end
  else
    STDERR.puts row.join(",")
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
