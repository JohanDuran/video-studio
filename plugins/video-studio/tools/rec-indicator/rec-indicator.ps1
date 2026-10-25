# Floating recording indicator.
# Watches for a screen-recording ffmpeg (gdigrab/ddagrab) and shows an always-on-top pill:
#   red  "REC 0:42"   while recording
#   green "DONE 2:13" after it stops (click to dismiss, auto-hides after 2 min)
# The pill is excluded from screen capture, so it never appears in recordings.
# Drag it anywhere; the position is remembered. Started at logon by start-hidden.vbs.

$ErrorActionPreference = 'Stop'

# One instance only.
$created = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\JDKoderRecIndicator', [ref]$created)
if (-not $created) { exit }

Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing, System.Management -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Management;
using System.Media;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class RecIndicator : Form
{
    [DllImport("user32.dll")] static extern bool SetWindowDisplayAffinity(IntPtr hWnd, uint affinity);
    [DllImport("user32.dll")] static extern bool ReleaseCapture();
    [DllImport("user32.dll")] static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wp, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();

    const uint WDA_EXCLUDEFROMCAPTURE = 0x11;
    static readonly TimeSpan DoneVisible = TimeSpan.FromMinutes(2);

    readonly Timer timer = new Timer();
    readonly string posFile = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "rec-indicator.pos");
    readonly float scale;

    string state = "idle";           // idle | rec | done
    DateTime recStart, doneAt;
    TimeSpan lastLength;
    bool blink;

    public RecIndicator()
    {
        using (var g = Graphics.FromHwnd(IntPtr.Zero)) scale = g.DpiX / 96f;
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        TopMost = true;
        StartPosition = FormStartPosition.Manual;
        BackColor = Color.Black;
        DoubleBuffered = true;
        Size = new Size(S(128), S(38));
        Location = LoadPos();
        Cursor = Cursors.SizeAll;

        var path = new GraphicsPath();
        int r = Height;
        path.AddArc(0, 0, r, r, 90, 180);
        path.AddArc(Width - r, 0, r, r, 270, 180);
        path.CloseFigure();
        Region = new Region(path);

        // Drag to move. The drag call returns when the mouse is released; if the pill
        // didn't move it was a click, which dismisses the green "done" pill.
        MouseDown += (s, e) =>
        {
            if (e.Button != MouseButtons.Left) return;
            var before = Location;
            ReleaseCapture();
            SendMessage(Handle, 0xA1, (IntPtr)2, IntPtr.Zero);   // WM_NCLBUTTONDOWN, HTCAPTION
            if (Location == before) { if (state == "done") { state = "idle"; Hide(); } }
            else SavePos();
        };

        timer.Interval = 500;
        timer.Tick += (s, e) => Tick();
        timer.Start();
    }

    int S(int v) { return (int)Math.Round(v * scale); }

    protected override CreateParams CreateParams
    {
        get
        {
            var cp = base.CreateParams;
            cp.ExStyle |= 0x80 | 0x08000000 | 0x8;   // TOOLWINDOW | NOACTIVATE | TOPMOST
            return cp;
        }
    }
    protected override bool ShowWithoutActivation { get { return true; } }

    protected override void OnHandleCreated(EventArgs e)
    {
        base.OnHandleCreated(e);
        SetWindowDisplayAffinity(Handle, WDA_EXCLUDEFROMCAPTURE);
    }

    int checkCounter;
    bool cachedRecording;

    // ffmpeg with a screen-grab input = a screen recording.
    bool IsRecording()
    {
        if (Process.GetProcessesByName("ffmpeg").Length == 0) return false;
        try
        {
            using (var q = new ManagementObjectSearcher(
                "SELECT CommandLine FROM Win32_Process WHERE Name='ffmpeg.exe'"))
                foreach (ManagementObject p in q.Get())
                {
                    var cl = ((p["CommandLine"] as string) ?? "").ToLowerInvariant();
                    if (cl.Contains("gdigrab") || cl.Contains("ddagrab")) return true;
                }
        }
        catch { }
        return false;
    }

    void Tick()
    {
        // Full check once a second; blink every half second.
        if (checkCounter++ % 2 == 0) cachedRecording = IsRecording();
        bool rec = cachedRecording;

        if (rec && state != "rec")
        {
            state = "rec"; recStart = DateTime.Now;
            ShowPill();
        }
        else if (!rec && state == "rec")
        {
            state = "done"; doneAt = DateTime.Now; lastLength = doneAt - recStart;
            try { SystemSounds.Asterisk.Play(); } catch { }
        }
        else if (state == "done" && DateTime.Now - doneAt > DoneVisible)
        {
            state = "idle"; Hide();
        }

        if (state != "idle") { TopMost = true; blink = !blink; Invalidate(); }
    }

    void ShowPill()
    {
        if (!Visible) Show();
        TopMost = true;
    }

    static string Fmt(TimeSpan t)
    {
        return t.TotalHours >= 1 ? t.ToString(@"h\:mm\:ss") : string.Format("{0}:{1:00}", (int)t.TotalMinutes, t.Seconds);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAliasGridFit;

        bool rec = state == "rec";
        var bg = rec ? Color.FromArgb(200, 20, 30) : Color.FromArgb(20, 150, 70);
        g.Clear(bg);

        int d = S(14), x = S(13), y = (Height - d) / 2;
        if (rec)
        {
            var dot = blink ? Color.White : Color.FromArgb(255, 170, 170);
            using (var b = new SolidBrush(dot)) g.FillEllipse(b, x, y, d, d);
        }
        else
        {
            using (var p = new Pen(Color.White, S(3)))
            { p.StartCap = p.EndCap = LineCap.Round;
              g.DrawLines(p, new[] { new Point(x + S(1), y + d / 2), new Point(x + d / 2 - S(1), y + d - S(2)), new Point(x + d, y + S(1)) }); }
        }

        string text = rec ? "REC " + Fmt(DateTime.Now - recStart) : "DONE " + Fmt(lastLength);
        using (var f = new Font("Segoe UI", 11f, FontStyle.Bold))
        using (var b = new SolidBrush(Color.White))
        {
            var r = new RectangleF(x + d + S(8), 0, Width - (x + d + S(8)), Height);
            var sf = new StringFormat { LineAlignment = StringAlignment.Center };
            g.DrawString(text, f, b, r, sf);
        }
    }

    Point LoadPos()
    {
        try
        {
            var parts = File.ReadAllText(posFile).Split(',');
            var p = new Point(int.Parse(parts[0]), int.Parse(parts[1]));
            foreach (var sc in Screen.AllScreens)
                if (sc.WorkingArea.Contains(p)) return p;
        }
        catch { }
        var wa = Screen.PrimaryScreen.WorkingArea;
        return new Point(wa.Right - Width - S(24), wa.Top + S(24));
    }

    void SavePos()
    {
        try { File.WriteAllText(posFile, Location.X + "," + Location.Y); } catch { }
    }

    protected override void OnFormClosing(FormClosingEventArgs e) { SavePos(); base.OnFormClosing(e); }
}
'@

[RecIndicator]::SetProcessDPIAware() | Out-Null
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object RecIndicator
# Start hidden; the timer shows it when a recording begins.
$ctx = New-Object System.Windows.Forms.ApplicationContext
[System.Windows.Forms.Application]::Run($ctx)
