#!/usr/bin/env ruby
require 'yaml'
require 'bundler'
Bundler.require

ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: 'sentiment_analysis',
  username: 'sentiment',
  password: 'sentiment.analysis!'
)

class Article < ActiveRecord::Base
  validates :url, uniqueness: true, length: {maximum: 1023}
  validates :title, length: {maximum: 255}
  validates :source, length: {maximum: 255}
end

def check_nan(nan)
  if nan.is_a?(Float) && nan.nan?
    0
  else
    nan
  end
end

r = RSRuby.instance

r.eval_R("suppressMessages(library('tm.plugin.webmining'))")
r.eval_R("suppressMessages(library('tm.plugin.sentiment'))")
web_corpus = r.eval_R("corpus <- WebCorpus(GoogleNewsSource('#{ARGV[0]}'))")
r.eval_R('corpus <- score(corpus)')
meta_corpus = r.eval_R('meta(corpus)')

web_corpus.each_with_index { |body, i|
  date = r.eval_R("meta(corpus[[#{i+1}]], 'DateTimeStamp')")
  article = Article.new(
    url: r.eval_R("meta(corpus[[#{i+1}]], 'Origin')"),
    published_on: "#{date['mday']}/#{date['mon']+1}/#{date['year']+1900}",
    title: r.eval_R("meta(corpus[[#{i+1}]], 'Heading')"),
    body: body.force_encoding('UTF-8'),
    polarity: check_nan(meta_corpus['polarity'][i]),
    subjectivity: check_nan(meta_corpus['subjectivity'][i]),
    pos_refs_per_ref: check_nan(meta_corpus['pos_refs_per_ref'][i]),
    neg_refs_per_ref: check_nan(meta_corpus['neg_refs_per_ref'][i]),
    senti_diffs_per_ref: check_nan(meta_corpus['neg_refs_per_ref'][i])
  )
  article.source = article.title.match(/ - (.+?)\z/)[1]
  article.save if ARGV[1] == 'save'
  puts article.to_yaml
}
