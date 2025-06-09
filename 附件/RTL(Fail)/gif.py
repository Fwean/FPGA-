import serial
import serial.tools.list_ports  # 修复错误的关键导入
import numpy as np
from PIL import Image, ImageSequence, ImageDraw, ImageFont
import time
import os
import keyboard


def process_image_to_bitmap(image, threshold=128, invert=False):
    """
    将图像转换为8x8黑白位图数据
    :param image: PIL图像对象
    :param threshold: 二值化阈值 (0-255)
    :param invert: 是否反转黑白
    :return: 8字节列表 (每行1字节)
    """
    # 调整大小为8x8
    small_img = image.resize((8, 8))

    # 转换为灰度图
    gray_img = small_img.convert('L')

    # 转换为二值数组
    img_array = np.array(gray_img)

    # 二值化处理 (黑灭白亮)
    if invert:
        bin_array = img_array <= threshold
    else:
        bin_array = img_array > threshold

    # 转换为字节数组 (每行1字节)
    byte_frame = []
    for y in range(8):
        byte_val = 0
        for x in range(8):
            if bin_array[y, x]:  # 白色像素
                # MSB对应左端，LSB对应右端
                byte_val |= (1 << (7 - x))
        byte_frame.append(byte_val)

    return byte_frame


def convert_gif_to_bitmaps(gif_path, threshold=128, invert=False, frame_limit=None):
    """
    转换GIF为8x8黑白位图序列
    :param gif_path: GIF文件路径
    :param threshold: 二值化阈值
    :param invert: 是否反转黑白
    :param frame_limit: 最大帧数限制
    :return: 位图序列列表
    """
    try:
        gif = Image.open(gif_path)
    except IOError:
        print(f"无法打开文件: {gif_path}")
        return []

    frames = []

    # 处理每帧图像
    for i, frame in enumerate(ImageSequence.Iterator(gif)):
        # 如果设置了帧限制，且超过了则停止
        if frame_limit is not None and i >= frame_limit:
            break

        # 转换为位图
        frame_data = process_image_to_bitmap(frame, threshold, invert)
        frames.append(frame_data)

    return frames


def create_text_frame(text, font_size=8, invert=False):
    """
    创建文字帧
    :param text: 要显示的文字
    :param font_size: 字体大小
    :param invert: 是否反转黑白
    :return: 位图数据
    """
    # 创建32x32空白图像 (为了文字清晰)
    img = Image.new('L', (8, 8), 255 if invert else 0)
    draw = ImageDraw.Draw(img)

    try:
        # 尝试加载字体
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        # 使用默认字体
        font = ImageFont.load_default()

    # 计算文字位置
    try:
        # 新版本PIL使用textbbox
        if hasattr(ImageDraw, 'textbbox'):
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
        else:
            # 旧版本PIL使用textsize
            text_width, text_height = draw.textsize(text, font)
    except:
        # 如果两种方法都失败，使用默认尺寸
        text_width, text_height = 30, 10

    x = (32 - text_width) // 2
    y = (32 - text_height) // 2

    # 绘制文字
    draw.text((x, y), text, fill=0 if invert else 255, font=font)

    # 转换为位图
    return process_image_to_bitmap(img, threshold=128, invert=invert)


def connect_serial(port, baudrate=115200):
    """
    连接到串口
    """
    try:
        ser = serial.Serial(
            port=port,
            baudrate=baudrate,
            bytesize=8,
            parity='N',
            stopbits=1,
            timeout=1
        )
        print(f"已连接到 {port}，波特率 {baudrate}")
        return ser
    except serial.SerialException as e:
        print(f"无法打开串口: {e}")
        return None
    except Exception as e:
        print(f"连接串口时出错: {e}")
        return None


def send_brightness(ser, brightness):
    """
    发送亮度设置命令
    """
    try:
        cmd = bytearray([0xAA, 0x55, 0xBC, brightness])
        ser.write(cmd)
        print(f"亮度设置: {brightness}")
        return True
    except serial.SerialException:
        print("发送亮度命令失败")
        return False
    except Exception as e:
        print(f"发送亮度命令时出错: {e}")
        return False


def display_gif(ser, gif_path, frame_delay=0.1, brightness=128, threshold=128,
                invert=False, frame_limit=None):
    """
    显示GIF动画
    """
    if not ser or not ser.is_open:
        print("串口未连接")
        return False

    try:
        # 设置初始亮度
        send_brightness(ser, brightness)

        # 转换GIF
        frames = convert_gif_to_bitmaps(gif_path, threshold, invert, frame_limit)

        if not frames:
            print("无有效帧数据")
            return False

        print(f"开始显示 {len(frames)} 帧动画")

        frame_count = 0
        last_time = time.time()

        while True:
            for frame in frames:
                # 发送单帧 (8字节)
                try:
                    ser.write(bytes(frame))
                    frame_count += 1

                    # 每秒打印帧率
                    current_time = time.time()
                    if current_time - last_time >= 1.0:
                        fps = frame_count / (current_time - last_time)
                        print(f"帧率: {fps:.1f} FPS")
                        frame_count = 0
                        last_time = current_time

                except serial.SerialException:
                    print("发送帧数据失败")
                    return False

                # 控制帧率
                time.sleep(frame_delay)

    except KeyboardInterrupt:
        print("\n显示中断")
        return True
    except Exception as e:
        print(f"显示动画时出错: {e}")
        return False


def display_text_sequence(ser, text_list, frame_delay=1.0, brightness=128,
                          font_size=16, invert=False):
    """
    显示文字序列
    """
    if not ser or not ser.is_open:
        print("串口未连接")
        return False

    try:
        # 设置初始亮度
        send_brightness(ser, brightness)

        print(f"开始显示文字序列: {len(text_list)} 条")

        frame_count = 0
        last_time = time.time()

        while True:
            for text in text_list:
                # 创建文字帧
                frame = create_text_frame(text, font_size, invert)

                # 显示文本 (持续frame_delay秒)
                frames_to_display = max(1, int(frame_delay / 0.1))
                for _ in range(frames_to_display):
                    # 发送单帧
                    try:
                        ser.write(bytes(frame))
                        frame_count += 1

                        # 每秒打印帧率
                        current_time = time.time()
                        if current_time - last_time >= 1.0:
                            fps = frame_count / (current_time - last_time)
                            print(f"帧率: {fps:.1f} FPS")
                            frame_count = 0
                            last_time = current_time

                    except serial.SerialException:
                        print("发送帧数据失败")
                        return False

                    # 控制刷新率 (10Hz)
                    time.sleep(0.1)

    except KeyboardInterrupt:
        print("\n显示中断")
        return True
    except Exception as e:
        print(f"显示文字时出错: {e}")
        return False


def main_menu(ser):
    """主菜单"""
    while True:
        print("\nLED点阵显示系统")
        print("1. 显示GIF动画")
        print("2. 显示文本")
        print("3. 设置亮度")
        print("4. 更换串口")
        print("5. 退出")

        choice = input("请选择操作: ").strip()

        if choice == "1":  # 显示GIF
            gif_path = input("输入GIF文件路径: ").strip()
            threshold = int(input("二值化阈值(0-255, 默认128): ") or "128")
            invert = input("反转黑白?(y/n): ").lower() == "y"
            frame_delay = float(input("帧延迟(秒, 默认0.1): ") or "0.1")
            frame_limit = input("最大帧数(不填则全部显示): ").strip()
            frame_limit = int(frame_limit) if frame_limit else None

            display_gif(ser, gif_path, frame_delay, 128, threshold, invert, frame_limit)

        elif choice == "2":  # 显示文本
            text_input = input("输入要显示的文本(多条用分号分隔): ").strip()
            texts = [t.strip() for t in text_input.split(";") if t.strip()]
            if not texts:
                texts = ["HELLO", "FPGA", "LED 8x8"]

            frame_delay = float(input("每帧显示时间(秒, 默认1.0): ") or "1.0")
            invert = input("反转黑白?(y/n): ").lower() == "y"

            display_text_sequence(ser, texts, frame_delay, 128, 12, invert)

        elif choice == "3":  # 设置亮度
            brightness = int(input("设置亮度(0-255): ").strip())
            if 0 <= brightness <= 255:
                send_brightness(ser, brightness)
            else:
                print("亮度值必须在0-255之间")

        elif choice == "4":  # 更换串口
            ser.close()
            # 获取可用串口列表
            ports = serial.tools.list_ports.comports()
            if not ports:
                print("未找到可用串口")
                return

            print("可用串口:")
            for i, port in enumerate(ports):
                print(f"{i + 1}. {port.device}")

            port_index = int(input("选择串口(输入编号): ")) - 1
            selected_port = ports[port_index].device if 0 <= port_index < len(ports) else ports[0].device

            ser = connect_serial(selected_port)
            if not ser:
                return  # 连接失败则退出

        elif choice == "5":  # 退出
            ser.close()
            print("程序退出")
            return

        else:
            print("无效选择")


if __name__ == "__main__":
    print("8x8 LED点阵控制系统")

    # 获取可用串口列表
    ports = serial.tools.list_ports.comports()
    if not ports:
        print("未找到可用串口")
        exit()

    print("可用串口:")
    for i, port in enumerate(ports):
        print(f"{i + 1}. {port.device}")

    # 选择串口
    try:
        port_index = int(input("选择串口(输入编号): ")) - 1
        selected_port = ports[port_index].device if 0 <= port_index < len(ports) else ports[0].device
    except:
        selected_port = ports[0].device

    # 连接串口
    ser = connect_serial(selected_port)
    if ser:
        # 添加键盘控制
        try:
            ser.brightness = 128


            def increase_brightness():
                new_bright = min(ser.brightness + 20, 255)
                if send_brightness(ser, new_bright):
                    ser.brightness = new_bright


            def decrease_brightness():
                new_bright = max(ser.brightness - 20, 0)
                if send_brightness(ser, new_bright):
                    ser.brightness = new_bright


            keyboard.add_hotkey('up', increase_brightness)
            keyboard.add_hotkey('down', decrease_brightness)
            keyboard.add_hotkey('ctrl+0', lambda: send_brightness(ser, 128))

            print("\n快捷键:")
            print("  ↑ : 亮度增加")
            print("  ↓ : 亮度减少")
            print("  Ctrl+0 : 恢复默认亮度")

            # 进入主菜单
            main_menu(ser)

        except KeyboardInterrupt:
            print("程序被中断")
        finally:
            if ser and ser.is_open:
                ser.close()
    else:
        print("无法连接串口，程序退出")