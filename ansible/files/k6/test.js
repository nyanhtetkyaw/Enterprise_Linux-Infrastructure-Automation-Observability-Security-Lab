import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 10,
  duration: '30s',

  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
  },
};

export default function () {
  const response = http.get('http://haproxy-lb:8080');

  check(response, {
    'HTTP status is 200': (r) => r.status === 200,
    'response contains HTTPD SERVER': (r) =>
      r.body.includes('HTTPD SERVER'),
  });

  sleep(1);
}
