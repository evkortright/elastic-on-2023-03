

DELETE shipments

GET shipments/_search

GET shipments/_mapping

GET shipments/_search
{
  "_source": false, 
  "fields": [
    "*"
  ]
}

GET shipments/_search
{
  "fields": [
    "origin",
    "destination"
  ], 
  "runtime_mappings": {
    "origin": {
      "type": "geo_point",
      "script": {
        "lang": "painless",
        "source": """
          Map data = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['origin']);
          emit(data.lat, data.lon);
        """
      }
    }
  }
}


GET shipments/_search
{
  "fields": [
    "origin",
    "destination"
  ],
  "runtime_mappings": {
    "origin": {
      "type": "geo_point",
      "script": {
        "lang": "painless",
        "source": """
          Map data = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['origin']);
          emit(data.lat, data.lon);
        """
      }
    },
    "destination": {
      "type": "geo_point",
      "script": {
        "lang": "painless",
        "source": """
          Map data = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['destination']);
          emit(data.lat, data.lon);
        """
      }
    }
  }
}

GET shipments/_search
{
  "fields": [
    "origin",
    "destination",
    "distance"
    ],
    "runtime_mappings": {
      "origin": {
        "type": "geo_point",
        "script": {
          "lang": "painless",
          "source": """
          Map data = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['origin']);
          emit(data.lat, data.lon);
          """
        }
      },
      "destination": {
        "type": "geo_point",
        "script": {
          "lang": "painless",
          "source": """
          Map data = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['destination']);
          emit(data.lat, data.lon);
          """
        }
      },
      "distance": {
        "type": "double",
        "script": {
          "lang": "painless",
          "source": """
          double haversineDistance(double lat1Deg, double lon1Deg, double lat2Deg, double lon2Deg, String unit) {
            double r = 6371; // Avg of Earth radius at poles and at equator
            if (unit == "mi") {
              r = 3957.3925;
            }
            double lat1 = Math.toRadians(lat1Deg);
            double lon1 = Math.toRadians(lon1Deg);
            double lat2 = Math.toRadians(lat2Deg);
            double lon2 = Math.toRadians(lon2Deg);
            double latDiff = (lat2 - lat1)/2;
            double lonDiff = (lon2 - lon1)/2;
            double sinLatDiff = Math.sin(latDiff);
            double sinLatDiffSq = sinLatDiff * sinLatDiff;
            double sinLonDiff = Math.sin(lonDiff);
            double sinLonDiffSq = sinLonDiff * sinLonDiff;
            double d = 2 * r * Math.asin(Math.sqrt(sinLatDiffSq + Math.cos(lat1) * Math.cos(lat2) * sinLonDiffSq));
            return d;
          }
          
          GeoPoint origin = doc['origin'].value;
          GeoPoint destination = doc['destination'].value;
          
          double distance = haversineDistance(origin.getLat(), origin.getLon(), destination.getLat(), destination.getLon(), "mi");
          
          emit(distance);
          """
        }
      }
    }
}

PUT shipments/_mapping
{
  "runtime": {
    "origin": {
      "type": "geo_point",
      "script": {
        "lang": "painless",
        "source": """
        Map data = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['origin']);
        emit(data.lat, data.lon);
        """
      }
    },
    "destination": {
      "type": "geo_point",
      "script": {
        "lang": "painless",
        "source": """
        Map data = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['destination']);
        emit(data.lat, data.lon);
        """
      }
    },
    "distance": {
      "type": "double",
      "script": {
        "lang": "painless",
        "source": """
        double haversineDistance(double lat1Deg, double lon1Deg, double lat2Deg, double lon2Deg, String unit) {
          double r = 6371; // Avg of Earth radius at poles and at equator
          if (unit == "mi") {
            r = 3957.3925;
          }
          double lat1 = Math.toRadians(lat1Deg);
          double lon1 = Math.toRadians(lon1Deg);
          double lat2 = Math.toRadians(lat2Deg);
          double lon2 = Math.toRadians(lon2Deg);
          double latDiff = (lat2 - lat1)/2;
          double lonDiff = (lon2 - lon1)/2;
          double sinLatDiff = Math.sin(latDiff);
          double sinLatDiffSq = sinLatDiff * sinLatDiff;
          double sinLonDiff = Math.sin(lonDiff);
          double sinLonDiffSq = sinLonDiff * sinLonDiff;
          double d = 2 * r * Math.asin(Math.sqrt(sinLatDiffSq + Math.cos(lat1) * Math.cos(lat2) * sinLonDiffSq));
          return d;
        }
        
        GeoPoint origin = doc['origin'].value;
        GeoPoint destination = doc['destination'].value;
        
        double distance = haversineDistance(origin.getLat(), origin.getLon(), destination.getLat(), destination.getLon(), "mi");
        
        emit(distance);
        """
      }
    }
  }
}

GET shipments/_search
{
  "size": 0,
  "aggs": {
    "by_distance": {
      "range": {
        "field": "distance",
        "ranges": [
          {
            "from": 0,
            "to": 50
          },
          {
            "from": 50,
            "to": 500
          },
          {
            "from": 500,
            "to": 1000
          },
          {
            "from": 1000,
            "to": 10000
          },
          {
            "from": 10000
          }
        ]
      },
      "aggs": {
        "shipments": {
          "top_hits": {
            "_source": true,
            "size": 1
          }
        }
      }
    }
  }
}
