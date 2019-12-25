defmodule Staubsauger do
  use GenServer
  use Bitwise

  @interface System.get_env("INTERFACE")
  @sleepcmd <<0xAA, 0xB4, 0x06, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x05, 0xAB>>
  @wakecmd <<0xAA, 0xB4, 0x06, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x06, 0xAB>>
  @sleep_interval 5_000
  @wake_interval 30_000

  @impl true
  def init(_state) do
    {:ok, pid} = Circuits.UART.start_link
    :ok = Circuits.UART.open(pid, @interface, speed: 9600, active: true)
    Process.send_after(self(), :sleep, @sleep_interval)
    {:ok, [interface: pid]}
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, ["state"], opts)
  end

  @impl true
  def handle_info({:circuits_uart, @interface, data}, state) do
    case parse_data(data) do
      {:ok, :sleep} -> IO.puts "Mode: Sleep"
      {:ok, :wake} -> IO.puts "Mode: Wake"
      {:ok, parsed_data} -> print_data(parsed_data)
      {:error, :incorrect_checksum} -> IO.puts "Incorrect Checksum"
      {:error, [unhandled_data: _]} -> IO.puts "Unhandled Data"
    end
    {:noreply, state}
  end

  def handle_info(:sleep, state) do
    pid = Keyword.get(state, :interface)
    Circuits.UART.write(pid, @sleepcmd)
    Process.send_after(self(), :wake, @sleep_interval)
    {:noreply, state}
  end

  def handle_info(:wake, state) do
    pid = Keyword.get(state, :interface)
    Circuits.UART.write(pid, @wakecmd)
    Process.send_after(self(), :sleep, @wake_interval)
    {:noreply, state}
  end

  defp print_data(%{pm10: pm10, pm25: pm25}) do
    pm10 = colorize_pm10_level(pm10)
    pm25 = colorize_pm25_level(pm25)
    IO.puts "PM 10: #{pm10} | PM 2.5: #{pm25}"
  end

  defp parse_data(<<0xAA, 0xC0, d1, d2, d3, d4, d5, d6, checksum, 0xAB>>) do
    pm25 = d1 + (d2 <<< 8)
    pm10 = d3 + (d4 <<< 8)
    calculated_checksum = rem(d1+d2+d3+d4+d5+d6, 256)

    if checksum == calculated_checksum do
      {:ok, %{pm25: pm25, pm10: pm10}}
    else
      {:error, :incorrect_checksum}
    end
  end
  defp parse_data(<<0xAA, 0xC5, 0x06, 1, 0, _::40>>) do
    {:ok, :sleep}
  end
   defp parse_data(<<0xAA, 0xC5, 0x06, 1, 1, _::40>>) do
    {:ok, :wake}
  end

  defp parse_data(data) do
    {:error, [unhandled_data: data]}
  end

  defp colorize_pm10_level(pm10) do
    pm10_text = Integer.to_string(pm10)
    case pm10 do
      v when v > 100 -> Color.red(pm10_text)
      v when v > 50 -> Color.yellow(pm10_text)
      v when v <= 50 -> Color.green(pm10_text)
    end
  end

    defp colorize_pm25_level(pm25) do
    pm25_text = Integer.to_string(pm25)
    case pm25 do
      v when v > 50 -> Color.red(pm25_text)
      v when v > 25 -> Color.yellow(pm25_text)
      v when v <= 25 -> Color.green(pm25_text)
    end
  end
end
