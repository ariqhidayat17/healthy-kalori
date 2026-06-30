import urllib.request
import json

api_key = "AIzaSyDmIE78OkamR09008Ih--U1u5HhQZlfWJM"
url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key={api_key}"

chat_body = {
    'contents': [{'role': 'user', 'parts': [{'text': 'Hello'}]}],
    'systemInstruction': {
        'role': 'user',
        'parts': [{'text': 'You are a helpful AI.'}]
    },
    'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
    }
}

req = urllib.request.Request(url, data=json.dumps(chat_body).encode('utf-8'), headers={'Content-Type': 'application/json'})
try:
    with urllib.request.urlopen(req) as response:
        print("Chat Response:", response.status, response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print("Chat Error:", e.code, e.read().decode('utf-8'))

vision_body = {
    'contents': [{
        'role': 'user',
        'parts': [
            {'inlineData': {'mimeType': 'image/jpeg', 'data': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='}},
            {'text': 'Analisis foto makanan ini.'}
        ]
    }],
    'systemInstruction': {
        'parts': [{'text': 'Kamu ahli gizi.'}]
    },
    'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.1,
        'maxOutputTokens': 1500,
    }
}

req2 = urllib.request.Request(url, data=json.dumps(vision_body).encode('utf-8'), headers={'Content-Type': 'application/json'})
try:
    with urllib.request.urlopen(req2) as response:
        print("Vision Response:", response.status, response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print("Vision Error:", e.code, e.read().decode('utf-8'))

