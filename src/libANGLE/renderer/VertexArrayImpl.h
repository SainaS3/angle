//
// Copyright 2014 The ANGLE Project Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//

// VertexAttribImpl.h: Defines the abstract rx::VertexAttribImpl class.

#ifndef LIBANGLE_RENDERER_VERTEXARRAYIMPL_H_
#define LIBANGLE_RENDERER_VERTEXARRAYIMPL_H_

#include "common/angleutils.h"
#include "libANGLE/Buffer.h"
#include "libANGLE/VertexArray.h"

// This is a helper X macro for iterating over all dirty attribs/bindings. Useful for dirty bits.
static_assert(gl::MAX_VERTEX_ATTRIBS == 16, "Invalid max vertex attribs");
static_assert(gl::MAX_VERTEX_ATTRIB_BINDINGS == 16, "Invalid max vertex bindings");
#define ANGLE_VERTEX_INDEX_CASES(FUNC) \
    FUNC(0)                            \
    FUNC(1)                            \
    FUNC(2)                            \
    FUNC(3)                            \
    FUNC(4)                            \
    FUNC(5) FUNC(6) FUNC(7) FUNC(8) FUNC(9) FUNC(10) FUNC(11) FUNC(12) FUNC(13) FUNC(14) FUNC(15)

namespace rx
{
class ContextImpl;

class VertexArrayImpl : angle::NonCopyable
{
  public:
    VertexArrayImpl(const gl::VertexArrayState &state) : mState(state) {}
    virtual gl::Error syncState(const gl::Context *context,
                                const gl::VertexArray::DirtyBits &dirtyBits,
                                const gl::VertexArray::DirtyAttribBitsArray &attribBits,
                                const gl::VertexArray::DirtyBindingBitsArray &bindingBits)
    {
        return gl::NoError();
    }

    virtual void destroy(const gl::Context *context) {}
    virtual ~VertexArrayImpl() {}

  protected:
    const gl::VertexArrayState &mState;
};

}  // namespace rx

#endif // LIBANGLE_RENDERER_VERTEXARRAYIMPL_H_
