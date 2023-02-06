# Example 2. shipments
# Explore data using grok
# create a composite runtime field
# calculate a new field from existing data: distance
# use the field

GET shipments/_mapping

GET shipments/_search
{
  "size": 0, 
  "fields": [
    "direction.origin",
    "direction.destination",
    "distance"
    ], 
    "runtime_mappings": {
      "direction": {
        "type": "composite",
        "script": {
          "lang": "painless",
          "source": """
          Map origin = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['origin']);
          Map destination = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['destination']);
          emit(["origin": [origin.lon, origin.lat], "destination": [destination.lon, destination.lat]]);
          """
        },
        "fields": {
          "origin": {
            "type": "geo_point"
          },
          "destination": {
            "type": "geo_point"
          }
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
          
          GeoPoint origin = doc['direction.origin'].value;
          GeoPoint destination = doc['direction.destination'].value;
          
          double distance = haversineDistance(origin.getLat(), origin.getLon(), destination.getLat(), destination.getLon(), "mi");
          
          emit(distance);
          """
        }
      }
    },
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
              "size": 1
            }
          }
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
            "to": 100
          },
          {
            "from": 50,
            "to": 100
          },
          {
            "from": 100,
            "to": 500
          },
          {
            "from": 500,
            "to": 1000
          },
          {
            "from": 1000
          }
        ]
      }
    }
  }
}

PUT shipments/_mapping
{
  "runtime": {
        "direction": {
      "type": "composite",
      "script": {
        "lang": "painless",
        "source": """
          Map origin = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['origin']);
          Map destination = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['destination']);
          emit(["origin": [origin.lon, origin.lat], "destination": [destination.lon, destination.lat]]);
        """
      },
      "fields": {
        "origin": {
          "type": "geo_point"
        },
        "destination": {
          "type": "geo_point"
        }
      }
    }
  }
}

GET shipments/_search
{
  "_source": false,
  "fields": [
    "*"
  ],
  "query": {
    "match": {
      "origin": "Shreveport"
    }
  }
}

PUT shipments/_mapping
{
  "runtime": {
    "direction": {
      "type": "composite",
      "script": {
        "lang": "painless",
        "source": """
        Map origin = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['origin']);
        Map destination = grok("\\('%{NUMBER:lat:double}', '%{NUMBER:lon:double}'").extract(params['_source']['destination']);
        emit(["origin": [origin.lon, origin.lat], "destination": [destination.lon, destination.lat]]);
        """
      },
      "fields": {
        "origin": {
          "type": "geo_point"
        },
        "destination": {
          "type": "geo_point"
        }
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
        
        GeoPoint origin = doc['direction.origin'].value;
        GeoPoint destination = doc['direction.destination'].value;
        
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
            "size": 1
          }
        }
      }
    }
  }
}
