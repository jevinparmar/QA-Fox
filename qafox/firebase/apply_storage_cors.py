import json
import urllib.request
import urllib.error
import sys

def apply_cors():
    try:
        with open('/home/jevin/.config/configstore/firebase-tools.json') as f:
            tokens = json.load(f).get('tokens', {})
    except Exception as e:
        print(f"Error reading firebase credentials: {e}")
        return False

    token = tokens.get('access_token')
    if not token:
        print("No access token found in firebase-tools.json.")
        return False

    # Check for existing buckets
    req = urllib.request.Request(
        'https://storage.googleapis.com/storage/v1/b?project=qafox-c24eb',
        headers={'Authorization': f'Bearer {token}'}
    )

    try:
        resp = urllib.request.urlopen(req)
        data = json.loads(resp.read().decode())
        items = data.get('items', [])
        if not items:
            print("No storage bucket found yet for project qafox-c24eb.")
            print("Please create the storage bucket in the Firebase Console first.")
            return False

        for b in items:
            bucket_name = b['name']
            print(f"Found bucket: {bucket_name}")

            # Apply CORS
            cors_body = {
                "cors": [
                    {
                        "origin": ["*"],
                        "method": ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"],
                        "responseHeader": ["*"],
                        "maxAgeSeconds": 3600
                    }
                ]
            }

            patch_req = urllib.request.Request(
                f'https://storage.googleapis.com/storage/v1/b/{bucket_name}',
                data=json.dumps(cors_body).encode('utf-8'),
                headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'},
                method='PATCH'
            )

            try:
                patch_resp = urllib.request.urlopen(patch_req)
                print(f"Successfully applied CORS policy to bucket '{bucket_name}'!")
            except urllib.error.HTTPError as pe:
                print(f"Error applying CORS to {bucket_name}: {pe.code} {pe.read().decode()}")

        return True
    except urllib.error.HTTPError as e:
        print(f"HTTPError checking buckets: {e.code} {e.read().decode()}")
        return False

if __name__ == '__main__':
    apply_cors()
