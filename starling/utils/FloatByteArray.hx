package starling.utils;

import flash.errors.EOFError;
import openfl.utils.Endian;
import openfl.utils.Float32Array;
import openfl.utils.Int32Array;
import openfl.utils.UInt8Array;

@:final class FloatByteArray {

  public var endian(get, set):Endian;
  public var length(get, set):Int;
  public var position(get, set):Int;
  public var bytesAvailable(get, never):Int;

  public function new() {
  }

  inline public function clear() {
    floats_ = null;
    ints32_ = null;
    uints8_ = null;
    pos_ = 0;
    real_size_ = 0;
    size_ = 0;
  }

  public function writeBytes(src_ba:FloatByteArray, ?offset:Int = 0,
      ?length:Int = 0):Void {
//if (offset % 4 != 0) throw new Error("Not aligned by 4");
//if (length % 4 != 0) throw new Error("Not aligned by 4");
//trace("writeBytes", pos_, offset, length);
    var real_offset = offset >> 2;
    var real_length = length >> 2;
    if (length == 0) real_length = src_ba.size_ - real_offset;
    Resize(pos_ + real_length);
    // var arr_view = src_ba.ints32_.subarray(real_offset,
    //   real_offset + real_length);
    // ints32_.set(arr_view, pos_);
    //trace(pos_ + real_length, ints32_ == null, src_ba.ints32_ == null);
    if (ints32_ != null && src_ba.ints32_ != null) {
#if (!js)
      ints32_.buffer.blit(pos_ << 2, src_ba.ints32_.buffer, real_offset << 2,
        real_length << 2);
#else
      var tmp_pos = pos_;
      for(i in real_offset...real_offset + real_length)
        ints32_[tmp_pos++] = src_ba.ints32_[i];
#end
    }
    pos_ += real_length;
  }

  inline public function readFloat():Float {
    CheckReadPosition();
    return floats_[pos_++];
  }

  inline public function writeFloat(v:Float):Void {
    Resize(pos_ + 1);
    floats_[pos_++] = v;
  }

  inline public function readUnsignedInt():UInt {
    //trace("r", vec_, pos_);
    //trace("r", pos_, haxe.io.FPHelper.floatToI32(vec_[pos_]));
    CheckReadPosition();
    return ints32_[pos_++];
  }

  inline public function writeUnsignedInt(v:UInt):Void {
//    trace("wu");
    Resize(pos_ + 1);
    ints32_[pos_++] = v;
    //trace("u", v, haxe.io.FPHelper.i32ToFloat(v), haxe.io.FPHelper.floatToI32(vec_[pos_ - 1]), pos_ - 1);
  }

  inline public function readInt():Int {
    CheckReadPosition();
    return ints32_[pos_++];
  }

  inline public function writeInt(v:Int):Void {
    Resize(pos_ + 1);
    ints32_[pos_++] = v;
    //trace("i", v, haxe.io.FPHelper.i32ToFloat(v), haxe.io.FPHelper.floatToI32(vec_[pos_ - 1]));
  }

  inline public function get_float32_array():Float32Array {
    return floats_;
  }

  inline function get_endian():Endian { return endian_; }

  inline function set_endian(v:Endian):Endian { return endian_ = v; }

  inline function get_length():Int { return size_ << 2; }

  inline function set_length(v:Int):Int {
//if (v % 4 != 0) throw new Error("Not aligned by 4");
    Resize(v >> 2);
    size_ = v >> 2;
    return v;
  }

  inline function get_position():Int { return pos_ << 2; }

  inline function set_position(v:Int):Int {
//if (v % 4 != 0) throw new Error("Not aligned by 4");
    pos_ = v >> 2;
    return v;
  }

  inline function get_bytesAvailable():Int { return (size_ - pos_) << 2; }

  inline function CheckReadPosition():Void {
    if (pos_ >= size_) throw new EOFError();
  }

  inline function Resize(new_size:Int):Void {
    if (new_size < size_) return;
    var prev_size = size_;
    size_ = new_size;
    if (new_size > real_size_) {
      //trace("Resize: ", real_size_, new_size);
      real_size_ = Std.int(new_size * kAllocOverheadFactor);
      var prev_ints32 = ints32_;
      ints32_ = new Int32Array(real_size_);
      // if (prev_ints32 != null) {
      //   ints32_.set(prev_ints32, 0);
      // }
#if (!js)
      if (prev_ints32 != null)
        ints32_.buffer.blit(0, prev_ints32.buffer, 0, prev_size << 2);
#else
      for(i in 0...prev_size) ints32_[i] = prev_ints32[i];
#end
      floats_ = new Float32Array(ints32_.buffer);
      uints8_ = new UInt8Array(ints32_.buffer);
    }
  }

	public inline function get(index:Int):Int {
//trace("Maaniv: g", index, ints8_[index]);
    return uints8_[index];
	}


	public inline function set(index:Int, value:Int):Int {
//trace("Maaniv: ----------s", index, value);
    Resize(index >> 2);
    return uints8_[index] = value;
	}

  static inline var kAllocOverheadFactor:Float = 1.5;

  var floats_:Float32Array = null;
  var ints32_:Int32Array = null;
  var uints8_:UInt8Array = null;
  var pos_:Int = 0;
  var endian_:Endian = Endian.LITTLE_ENDIAN;
  var real_size_:Int = 0;
  var size_:Int = 0;
}
