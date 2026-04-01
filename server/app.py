"""
Claude Mobile Approver - Server Component
Flask-based approval web service with ntfy integration
"""

from flask import Flask, request, jsonify, render_template_string
import os
import json
import time
import requests

app = Flask(__name__)

# Configuration from environment
APPROVAL_DIR = os.environ.get('APPROVAL_DIR', '/opt/claude-approver/approvals')
NTFY_SERVER = os.environ.get('NTFY_SERVER', 'http://localhost:2586')
NTFY_USER = os.environ.get('NTFY_USER', 'claude')
NTFY_PASS = os.environ.get('NTFY_PASS', '')
NTFY_TOPIC = os.environ.get('NTFY_TOPIC', 'claude-approve')

os.makedirs(APPROVAL_DIR, exist_ok=True)

# HTML template for approval page
APPROVAL_PAGE = '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Claude Code Approval</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            min-height: 100vh;
            padding: 15px;
        }
        .container {
            max-width: 500px;
            margin: 0 auto;
            background: #fff;
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 25px;
            text-align: center;
            color: white;
        }
        .icon { font-size: 50px; margin-bottom: 10px; }
        .title { font-size: 22px; font-weight: 600; }
        .subtitle { font-size: 14px; opacity: 0.9; margin-top: 5px; }
        .content { padding: 20px; }
        .section { margin-bottom: 15px; }
        .section-title {
            font-size: 12px;
            color: #888;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .section-title::before {
            content: "";
            width: 4px;
            height: 14px;
            background: #667eea;
            border-radius: 2px;
        }
        .info-box {
            background: #f8f9fa;
            border-radius: 12px;
            padding: 15px;
        }
        .tool-name {
            font-size: 18px;
            font-weight: 600;
            color: #333;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .tool-badge {
            background: #667eea;
            color: white;
            font-size: 11px;
            padding: 4px 10px;
            border-radius: 20px;
            font-weight: 500;
        }
        .command-box {
            background: #1e1e1e;
            border-radius: 10px;
            padding: 15px;
            overflow-x: auto;
            max-height: 200px;
            overflow-y: auto;
        }
        .command-text {
            font-family: "SF Mono", "Monaco", "Inconsolata", monospace;
            font-size: 12px;
            color: #d4d4d4;
            white-space: pre-wrap;
            word-break: break-all;
            line-height: 1.5;
        }
        .suggestion-item {
            background: #f8f9fa;
            border: 2px solid #e0e0e0;
            border-radius: 12px;
            padding: 15px;
            margin-bottom: 10px;
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .suggestion-item:hover {
            border-color: #667eea;
            background: #f0f4ff;
        }
        .suggestion-item.selected {
            border-color: #34c759;
            background: #e8f5e9;
        }
        .suggestion-radio {
            width: 22px;
            height: 22px;
            border-radius: 50%;
            border: 2px solid #ccc;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }
        .suggestion-item.selected .suggestion-radio {
            border-color: #34c759;
            background: #34c759;
        }
        .suggestion-item.selected .suggestion-radio::after {
            content: "✓";
            color: white;
            font-size: 14px;
            font-weight: bold;
        }
        .suggestion-content { flex: 1; }
        .suggestion-title {
            font-weight: 600;
            color: #333;
            margin-bottom: 3px;
            font-size: 15px;
        }
        .suggestion-desc {
            font-size: 12px;
            color: #666;
        }
        .btn-group {
            display: flex;
            gap: 12px;
            padding: 20px;
            background: #f8f9fa;
        }
        .btn {
            flex: 1;
            padding: 16px;
            border: none;
            border-radius: 12px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
        }
        .btn:active { transform: scale(0.98); }
        .btn-approve {
            background: #34c759;
            color: white;
            box-shadow: 0 4px 15px rgba(52, 199, 89, 0.4);
        }
        .btn-deny {
            background: #ff3b30;
            color: white;
            box-shadow: 0 4px 15px rgba(255, 59, 48, 0.4);
        }
        .hidden { display: none !important; }
        .result-container {
            padding: 60px 30px;
            text-align: center;
        }
        .result-icon { font-size: 80px; margin-bottom: 15px; }
        .result-text { font-size: 20px; font-weight: 600; }
        .result-approved { color: #34c759; }
        .result-denied { color: #ff3b30; }
        .file-path {
            font-family: monospace;
            background: #fff3cd;
            padding: 10px 12px;
            border-radius: 8px;
            font-size: 12px;
            color: #856404;
            word-break: break-all;
            border-left: 3px solid #ffc107;
        }
        .loading { text-align: center; padding: 40px; color: #888; }
        .spinner {
            width: 40px; height: 40px;
            border: 3px solid #f0f0f0;
            border-top-color: #667eea;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 0 auto 15px;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
    </style>
</head>
<body>
    <div class="container" id="pending">
        <div class="header">
            <div class="icon">🤖</div>
            <div class="title">Claude Code</div>
            <div class="subtitle">Permission Request</div>
        </div>
        <div class="content">
            <div id="loading" class="loading">
                <div class="spinner"></div>
                <div>Loading...</div>
            </div>
            <div id="details" class="hidden">
                <div class="section">
                    <div class="section-title">Tool</div>
                    <div class="info-box">
                        <div class="tool-name">
                            <span id="toolIcon">🔧</span>
                            <span id="toolName">Unknown</span>
                            <span class="tool-badge" id="toolBadge">TOOL</span>
                        </div>
                    </div>
                </div>
                <div class="section" id="commandSection">
                    <div class="section-title">Command</div>
                    <div class="command-box">
                        <div class="command-text" id="commandText">Loading...</div>
                    </div>
                </div>
                <div class="section" id="suggestionsSection">
                    <div class="section-title">Options</div>
                    <div id="suggestionsList"></div>
                </div>
            </div>
        </div>
        <div class="btn-group" id="buttons">
            <button class="btn btn-approve" onclick="submit('approve')">✅ Approve</button>
            <button class="btn btn-deny" onclick="submit('deny')">❌ Deny</button>
        </div>
    </div>
    <div class="container hidden" id="result">
        <div class="result-container">
            <div class="result-icon" id="resultIcon"></div>
            <div class="result-text" id="resultText"></div>
        </div>
    </div>
    <script>
        var sessionId = window.location.pathname.split('/')[1];
        var selectedSuggestion = null;
        var toolIcons = {
            'Bash': '💻', 'Edit': '✏️', 'Write': '📝', 'Read': '📖',
            'Glob': '🔍', 'Grep': '🔎', 'WebFetch': '🌐', 'WebSearch': '🔍',
            'Agent': '🤖', 'TaskCreate': '📋', 'AskUserQuestion': '❓'
        };

        fetch('/api/' + sessionId)
            .then(r => r.json())
            .then(data => {
                document.getElementById('loading').classList.add('hidden');
                document.getElementById('details').classList.remove('hidden');

                var tool = data.tool || data.t || 'Unknown';
                var input = data.input || data.command || {};

                document.getElementById('toolIcon').textContent = toolIcons[tool] || '🔧';
                document.getElementById('toolName').textContent = tool;
                document.getElementById('toolBadge').textContent = tool.toUpperCase();

                var cmdText = '';
                if (tool === 'Bash') {
                    cmdText = input.command || data.command || 'No command';
                } else if (tool === 'Edit' || tool === 'Write') {
                    if (input.file_path) cmdText += '📁 ' + input.file_path + '\\n\\n';
                    if (input.old_string) cmdText += '--- Original ---\\n' + input.old_string + '\\n\\n';
                    if (input.new_string) cmdText += '+++ New ---\\n' + input.new_string;
                } else {
                    cmdText = JSON.stringify(input, null, 2);
                }
                document.getElementById('commandText').textContent = cmdText;

                var suggestions = data.suggestions || [];
                var sugHtml = '';
                suggestions.forEach((s, i) => {
                    var type = s.type || '';
                    var title = '', desc = '';
                    if (type === 'addRules' && s.rules && s.rules.length > 0) {
                        title = '🔒 Always Allow';
                        desc = s.rules[0].ruleContent ?
                            s.rules[0].ruleContent.substring(0, 50) :
                            'Save rule';
                    } else if (type === 'setMode') {
                        title = '🚀 Auto Mode';
                        desc = 'Mode: ' + s.mode;
                    }
                    if (title) {
                        sugHtml += '<div class="suggestion-item" data-idx="' + i + '" onclick="selectSuggestion(' + i + ')">';
                        sugHtml += '<div class="suggestion-radio"></div>';
                        sugHtml += '<div class="suggestion-content">';
                        sugHtml += '<div class="suggestion-title">' + title + '</div>';
                        sugHtml += '<div class="suggestion-desc">' + desc + '</div>';
                        sugHtml += '</div></div>';
                    }
                });
                if (sugHtml) {
                    document.getElementById('suggestionsList').innerHTML = sugHtml;
                } else {
                    document.getElementById('suggestionsSection').classList.add('hidden');
                }
            })
            .catch(e => {
                document.getElementById('loading').innerHTML =
                    '<div style="color:#ff3b30">Error: ' + e.message + '</div>';
            });

        function selectSuggestion(idx) {
            document.querySelectorAll('.suggestion-item').forEach(el => el.classList.remove('selected'));
            document.querySelector('.suggestion-item[data-idx="' + idx + '"]').classList.add('selected');
            selectedSuggestion = idx;
        }

        function submit(action) {
            document.getElementById('buttons').innerHTML =
                '<div style="padding:20px;text-align:center;color:#888">Processing...</div>';
            var url = '/api/' + sessionId + '/' + action;
            if (selectedSuggestion !== null) {
                url += '?suggestion=' + selectedSuggestion;
            }
            fetch(url, {method: 'POST'})
                .then(r => r.json())
                .then(d => {
                    document.getElementById('pending').classList.add('hidden');
                    document.getElementById('result').classList.remove('hidden');
                    var icon = document.getElementById('resultIcon');
                    var text = document.getElementById('resultText');
                    if (action === 'approve') {
                        icon.textContent = '✅';
                        text.textContent = 'Approved';
                        text.classList.add('result-approved');
                    } else {
                        icon.textContent = '❌';
                        text.textContent = 'Denied';
                        text.classList.add('result-denied');
                    }
                    setTimeout(function() { window.close(); }, 1500);
                });
        }
    </script>
</body>
</html>
'''


@app.route('/<session_id>')
def approval_page(session_id):
    """Serve the approval page"""
    return APPROVAL_PAGE


@app.route('/api/<session_id>')
def api_get(session_id):
    """Get request details"""
    filepath = f'{APPROVAL_DIR}/{session_id}.json'
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            data = json.load(f)
        # Parse input if it's a JSON string
        if 'command' in data and isinstance(data['command'], str):
            try:
                data['input'] = json.loads(data['command'])
            except:
                pass
        return jsonify(data)
    return jsonify({'tool': 'Unknown', 'status': 'pending'})


@app.route('/api/<session_id>/approve', methods=['POST'])
def approve(session_id):
    """Approve the request"""
    filepath = f'{APPROVAL_DIR}/{session_id}.json'
    suggestion_idx = request.args.get('suggestion', type=int)

    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            data = json.load(f)

        data['status'] = 'approved'
        data['approved_at'] = time.time()

        if suggestion_idx is not None:
            data['selected_suggestion'] = suggestion_idx
            suggestions = data.get('suggestions', [])
            if suggestion_idx < len(suggestions):
                data['selected_suggestion_data'] = suggestions[suggestion_idx]

        with open(filepath, 'w') as f:
            json.dump(data, f)

        return jsonify({'success': True, 'status': 'approved', 'suggestion': suggestion_idx})

    return jsonify({'success': False, 'error': 'not found'}), 404


@app.route('/api/<session_id>/deny', methods=['POST'])
def deny(session_id):
    """Deny the request"""
    filepath = f'{APPROVAL_DIR}/{session_id}.json'

    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            data = json.load(f)

        data['status'] = 'denied'
        data['denied_at'] = time.time()

        with open(filepath, 'w') as f:
            json.dump(data, f)

        return jsonify({'success': True, 'status': 'denied'})

    return jsonify({'success': False, 'error': 'not found'}), 404


@app.route('/request/<session_id>', methods=['POST'])
def create_request(session_id):
    """Create a new approval request"""
    data = {
        'status': 'pending',
        'created_at': time.time(),
        'tool': request.json.get('tool', 'unknown'),
        'command': request.json.get('command', ''),
        'input': request.json.get('input', {}),
        'description': request.json.get('description', ''),
        'suggestions': request.json.get('suggestions', [])
    }

    filepath = f'{APPROVAL_DIR}/{session_id}.json'
    with open(filepath, 'w') as f:
        json.dump(data, f)

    # Send ntfy notification
    try:
        approval_url = f'{request.host_url}{session_id}'
        requests.post(
            f'{NTFY_SERVER}/{NTFY_TOPIC}',
            auth=(NTFY_USER, NTFY_PASS),
            headers={
                'Title': f'🤖 {data["description"] or data["tool"]}',
                'Priority': 'high',
                'Tags': 'warning,claude',
                'Click': approval_url,
                'Actions': f'view, ✅ Approve, {approval_url}, clear=true'
            },
            data=f'Tool: {data["tool"]}',
            timeout=5
        )
    except Exception as e:
        print(f'Failed to send notification: {e}')

    return jsonify({'success': True, 'session_id': session_id})


@app.route('/check/<session_id>')
def check(session_id):
    """Check approval status"""
    filepath = f'{APPROVAL_DIR}/{session_id}.json'
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            return jsonify(json.load(f))
    return jsonify({'status': 'pending'})


@app.route('/cleanup/<session_id>', methods=['POST'])
def cleanup(session_id):
    """Clean up approval file"""
    filepath = f'{APPROVAL_DIR}/{session_id}.json'
    if os.path.exists(filepath):
        os.remove(filepath)
    return jsonify({'success': True})


@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'timestamp': time.time()})


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 2587))
    app.run(host='0.0.0.0', port=port, threaded=True)
