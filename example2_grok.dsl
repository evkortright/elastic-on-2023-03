# Example 2
# extract data from an unstructured message

# "message": """2023-02-02T06:49:28.178558Z	   97 Query	SELECT digest_text, count_star, avg_timer_wait, max_timer_wait, last_seen, quantile_95"""

PUT my-logs/_doc/1
{
  "message": """2023-02-02T06:49:28.178558Z	   97 Query	SELECT digest_text, count_star, avg_timer_wait, max_timer_wait, last_seen, quantile_95"""
}

GET my-logs/_doc/1

GET my-logs/_search
{
  "fields": [
    "mysql.general.command_type"
  ], 
  "runtime_mappings": {
    "mysql.general.command_type": {
      "type": "keyword",
      "script": {
        "lang": "painless",
        "source": """
          String message = doc['message.keyword'].value;
          Map data = grok("%{TIMESTAMP_ISO8601}%{SPACE}%{NUMBER:mysql.thread_id:int}%{SPACE}%{WORD:mysql.general.command_type}%{SPACE}%{GREEDYDATA:mysql.general.query_body}").extract(doc['message.keyword'].value);
          emit(data['mysql.general.command_type']);
        """
      }
    }
  }, 
  
  "query": {
    "match": {
      "mysql.general.command_type": "Query"
    }
  }
}
