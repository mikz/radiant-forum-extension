require 'sanitize'
class Post < ActiveRecord::Base
  has_site if respond_to? :has_site
  
  belongs_to :reader
  belongs_to :topic
  belongs_to :page
  has_many :attachments, :class_name => 'PostAttachment', :order => :position, :dependent => :destroy

  accepts_nested_attributes_for :topic
  accepts_nested_attributes_for :attachments, :allow_destroy => true
  validates_presence_of :reader, :body

  after_create :notify_holder_of_creation
  after_destroy :notify_holder_of_destruction
  
  default_scope :order => "posts.created_at DESC"
  
  named_scope :comments, :conditions => "page_id IS NOT NULL"
  named_scope :non_comments, :conditions => "page_id IS NULL"
  named_scope :imported, :conditions => "old_id IS NOT NULL"
  named_scope :in_topic, lambda { |topic| { :conditions => ["topic_id = ?", topic.id] }}
  named_scope :in_topics, lambda { |topics|
    ids = topics.map(&:id)
    { :conditions => ["topic_id IN (#{ids.map{"?"}.join(',')})", *ids] }
  }
  named_scope :from_reader, lambda { |reader| { :conditions => ["reader_id = ?", reader.id] }}
  named_scope :latest, lambda { |count| { :order => 'created_at DESC', :limit => count }}
  named_scope :except, lambda { |post| { :conditions => ["NOT posts.id = ?", post.id] }}
  named_scope :distinct_readers, :select => "DISTINCT posts.reader_id" do
    def count
      self.length  # replacing a SQL shortcut that omits the distinct clause
    end
  end
  named_scope :containing, lambda { |term|
    { 
      :conditions => ["posts.body LIKE :term OR topics.name LIKE :term", {:term => "%#{term}%"}],
      :joins => "LEFT OUTER JOIN topics on posts.topic_id = topics.id"
    }
  }

  # other extensions can attach chains here to limit access
  def self.visible_to(reader)
    self.scoped
  end

  def self.in_forum(forum)
    in_topics(forum.topics)
  end

  def holder
    page || topic
  end
    
  def comment?
    !!page
  end
  
  def page_when_paginated
    holder.page_for(self)
  end
  
  def forum
    topic.forum unless comment?
  end
  
  def first?
    !holder || holder.new_record? || holder.posts.first == self
  end

  def locked?
    holder && holder.locked?
  end
  
  def has_replies?
    holder.posts.last != self
  end
  
  def editable_interval
    Radiant::Config['forum.editable_period'].to_i.minutes if Radiant::Config['forum.editable_period']
  end
  
  def still_editable_for
    if editable_interval && still_editable?
      self.created_at + editable_interval - Time.now 
    else
      0
    end
  end
  
  def still_editable?
    !editable_interval || Time.now - self.created_at < editable_interval
  end
  
  def editable_by?(reader=nil)
    return false unless reader
    still_editable? && reader && (reader.id == reader_id)
  end

  def visible_to?(reader=nil)
    return true if reader || Radiant::Config['forum.public?']
  end
  
  # so that page comments can be rendered from a radius tag
  def body_html
    if body
      html = RedCloth.new(body, [ :hard_breaks, :filter_html ]).to_html(:textile, :smilies)
      Sanitize.clean(html, Sanitize::Config::RELAXED)
    else
      ""
    end
  end
    
  def date_html
    self.created_at.to_s
  end
  
  def save_attachments(files=nil)
    files.collect {|file| self.attachments.create(:file => file) unless file.blank? } if files
  end

  def notify_holder_of_destruction
    holder.notice_destruction_of(self)
  end

  def notify_holder_of_creation
    holder.notice_creation_of(self)
  end

  def dom_id
    "post_#{self.id}"
  end

end
