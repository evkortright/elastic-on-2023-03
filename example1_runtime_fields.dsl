# compare size of indices using runtime fields

GET people/_count

GET people/_mapping

GET _cat/indices/people?h=store.size



DELETE people2

PUT people2
{
  "mappings": {
    "dynamic": "runtime"
  }
}

POST _reindex
{
  "source": {
    "index": "people"
  },
  "dest": {
    "index": "people2"
  }
}

GET people2/_mapping

GET _cat/indices/people2?h=store.size

GET people2/_search
{
  "fields": [
    "*"
  ],
  "sort": [
    {
      "last_name": {
        "order": "asc"
      }
    },
    {
      "first_name": {
        "order": "asc"
      }
    }
  ]
}

