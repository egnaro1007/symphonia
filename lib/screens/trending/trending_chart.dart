import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/song.dart';
import '../../controller/player_controller.dart';

class TrendingChart extends StatefulWidget {
  final List<Song> songs;

  const TrendingChart({super.key, required this.songs});

  @override
  State<TrendingChart> createState() => _TrendingChartState();
}

class _TrendingChartState extends State<TrendingChart> {
  int _highlightedLine = 0; // 0 = line 1, 1 = line 2, 2 = line 3

  void _switchToNextLine() {
    setState(() {
      _highlightedLine = (_highlightedLine + 1) % 3; // Cycle between 0, 1, 2
    });
  }

  List<String> _getLast10Days() {
    final now = DateTime.now();
    final days = <String>[];

    // Tạo danh sách 10 ngày gần nhất, từ phải sang trái (ngày cũ nhất đến ngày mới nhất)
    for (int i = 9; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      days.add(date.day.toString().padLeft(2, '0'));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final last10Days = _getLast10Days();
    final now = DateTime.now();
    final formattedDate =
        "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}";

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Stack(
          children: [
            LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // Hiển thị ngày thực tế cho 10 ngày gần nhất
                        if (value.toInt() >= 0 &&
                            value.toInt() < last10Days.length) {
                          return Text(
                            last10Days[value.toInt()],
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 25,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Blue line (line 1)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 6.0 - 1.5),
                      FlSpot(1, 6.2 - 1.5),
                      FlSpot(2, 6.5 - 1.5), // Highest point for album cover
                      FlSpot(3, 6.3 - 1.5),
                      FlSpot(4, 5.8 - 1.5),
                      FlSpot(5, 5.9 - 1.5),
                      FlSpot(6, 6.1 - 1.5),
                      FlSpot(7, 5.5 - 1.5),
                      FlSpot(8, 5.8 - 1.5),
                      FlSpot(9, 5.4 - 1.5),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth:
                        _highlightedLine == 0
                            ? 4
                            : 2, // Highlight khi được chọn
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show:
                          _highlightedLine ==
                          0, // Chỉ hiển thị dot khi được highlight
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.blue,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Orange line (line 2)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3.2 - 1),
                      FlSpot(1, 3.5 - 1),
                      FlSpot(2, 4.0 - 1),
                      FlSpot(3, 4.2 - 1),
                      FlSpot(4, 4.0 - 1),
                      FlSpot(5, 3.8 - 1),
                      FlSpot(6, 4.6 - 1),
                      FlSpot(7, 3.7 - 1),
                      FlSpot(8, 3.5 - 1),
                      FlSpot(9, 3.2 - 1),
                    ],
                    isCurved: true,
                    color: Colors.orange,
                    barWidth:
                        _highlightedLine == 1
                            ? 4
                            : 2, // Highlight khi được chọn
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show:
                          _highlightedLine ==
                          1, // Chỉ hiển thị dot khi được highlight
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.orange,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Green line (line 3)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1.4 - 0.5),
                      FlSpot(1, 1.5 - 0.5),
                      FlSpot(2, 1.6 - 0.5),
                      FlSpot(3, 1.7 - 0.5),
                      FlSpot(4, 1.6 - 0.5),
                      FlSpot(5, 1.5 - 0.5),
                      FlSpot(6, 1.6 - 0.5),
                      FlSpot(7, 1.8 - 0.5),
                      FlSpot(8, 2.2 - 0.5),
                      FlSpot(9, 1.9 - 0.5),
                    ],
                    isCurved: true,
                    color: Colors.teal,
                    barWidth: _highlightedLine == 2 ? 4 : 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: _highlightedLine == 2,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.teal,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                minX: 0,
                maxX: 9,
                minY: 0,
                maxY: 8,
              ),
            ),
            // Album cover at highest point - shows song based on highlighted line
            if (widget.songs.length > _highlightedLine)
              Positioned(
                left: _calculateAlbumPosition(),
                top: _calculateAlbumTopPosition(),
                child: GestureDetector(
                  onTap: _switchToNextLine, // Switch line instead of song
                  child: Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Album cover image - show song based on highlighted line
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            widget
                                .songs[_highlightedLine]
                                .imagePath, // Use highlighted line song
                            width: 55,
                            height: 55,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 55,
                                height: 55,
                                color: Colors.grey.shade800,
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              );
                            },
                          ),
                        ),
                        // Line indicator overlay instead of ranking number
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _getLineColor(),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${_highlightedLine + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Date and play button in top right corner
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date text
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Play button
                  GestureDetector(
                    onTap: () async {
                      // Play all trending songs using PlayerController
                      if (widget.songs.isNotEmpty) {
                        final PlayerController playerController =
                            PlayerController.getInstance();
                        await playerController.loadSongs(widget.songs, 0);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLineColor() {
    switch (_highlightedLine) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  double _calculateAlbumPosition() {
    // Get the highest point x-coordinate for each line
    double highestPointX;
    switch (_highlightedLine) {
      case 0: // Blue line - highest at x=2 (6.5 - 1.5 = 5.0)
        highestPointX = 1.9;
        break;
      case 1: // Orange line - highest at x=7
        highestPointX = 6.5;
        break;
      case 2: // Green line - highest at x=9
        highestPointX = 8.9;
        break;
      default:
        highestPointX = 2.0;
    }

    // Calculate position based on chart width and highest point
    const chartPadding = 32.0; // 16*2 padding
    const availableWidth = 360.0 - chartPadding;
    final position = (highestPointX / 9.0) * availableWidth;
    return position + 16 - 27.5; // Center the 55px album cover
  }

  double _calculateAlbumTopPosition() {
    // Get the highest point y-coordinate for each line and calculate top position
    double highestPointY;
    switch (_highlightedLine) {
      case 0: // Blue line - highest at y=5.0 (6.5 - 1.5)
        highestPointY = 6.6;
        break;
      case 1: // Orange line - highest at y=3.2 (4.2 - 1)
        highestPointY = 5.2;
        break;
      case 2: // Green line - highest at y=1.2 (1.7 - 0.5)
        highestPointY = 3.3;
        break;
      default:
        highestPointY = 5.0;
    }

    // Convert chart y-coordinate to screen position
    // Chart height is about 200px (250 - 50 for padding/titles)
    // Chart y range is 0-8, so each unit is 25px
    const chartHeight = 200.0;
    const chartYRange = 8.0;
    const pixelsPerUnit = chartHeight / chartYRange;

    // Calculate top position (invert because screen coordinates go down)
    final topPosition = (chartYRange - highestPointY) * pixelsPerUnit;
    return topPosition - 27.5; // Center the 55px album cover vertically
  }
}
